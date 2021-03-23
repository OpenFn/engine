defmodule Engine.Scheduler do
  @moduledoc false

  use Quantum, otp_app: nil
end

defmodule Engine.Supervisor do
  use Supervisor
  require Logger

  @defaults [
    run_broadcaster_name: :engine_run_broadcaster,
    job_state_repo_name: :engine_job_state_repo,
    job_state_basedir: "./tmp"
  ]

  def start_link(config) do
    name =
      config[:name] ||
        raise ArgumentError, "the :name option is required when starting Engine"

    config[:project_config] ||
      raise ArgumentError, ":project_config is required to start an engine."

    sup_name = Module.concat(name, "Supervisor")
    Supervisor.start_link(__MODULE__, config, name: sup_name)
  end

  def init(config) do
    name = config[:name]
    project_config = Engine.Config.parse!(config[:project_config])

    Logger.debug(inspect(project_config))

    job_state_repo_opts = %Engine.JobStateRepo.StartOpts{
      name: config[:job_state_repo_name],
      basedir: config[:job_state_basedir]
    }

    run_registry = String.to_atom("#{name}_registry")

    registry = [
      meta: [project_config: project_config],
      keys: :unique,
      name: run_registry
    ]

    scheduler_jobs =
      Engine.Config.triggers(project_config, :cron)
      |> Enum.map(fn t ->
        {String.to_atom(t.name),
         [
           schedule: t.cron,
           task: {
             Engine,
             :handle_trigger,
             [config[:run_broadcaster_name], t]
           }
         ]}
      end)
      |> Keyword.new()

    run_broadcaster_opts = %Engine.RunBroadcaster.StartOpts{
      name: config[:run_broadcaster_name],
      config: project_config,
      run_dispatcher: :run_dispatcher,
      job_state_repo: config[:job_state_repo_name]
    }

    run_dispatcher_opts = %Engine.RunDispatcher.StartOpts{
      name: :run_dispatcher,
      # TODO: CHANGEME
      queue: :run_task_queue,
      # TODO: CHANGEME
      task_supervisor: :task_supervisor,
      job_state_repo: config[:job_state_repo_name],
      run_broadcaster: config[:run_broadcaster_name],
      adaptors_path: config[:adaptors_path],
      temp_opts: %{basedir: "./tmp"}
    }

    # start scheduler around here
    children = [
      {Engine.JobStateRepo, job_state_repo_opts},
      %{id: OPQ, start: {OPQ, :init, [[name: :run_task_queue]]}},
      {Registry, registry},
      {Engine.RunBroadcaster, run_broadcaster_opts},
      {Engine.RunDispatcher, run_dispatcher_opts},
      {Engine.Scheduler, [id: name, name: Engine.Scheduler, jobs: scheduler_jobs]},
      {Task.Supervisor, [name: :task_supervisor]}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end

  def compile_config(otp_app, module, opts) do
    conf =
      case Application.fetch_env(otp_app, module) do
        {:ok, conf} -> conf
        :error -> []
      end

    @defaults
    |> Keyword.merge(name: module)
    |> Keyword.merge(conf)
    |> Keyword.merge(opts)
  end

  def runtime_config(compile_config, opts) do
    conf =
      case Application.fetch_env(compile_config[:otp_app], compile_config[:name]) do
        {:ok, conf} -> conf
        :error -> []
      end

    compile_config
    |> Keyword.merge(conf)
    |> Keyword.merge(opts)
  end
end
