defmodule OpenFn.Engine.Scheduler do
  @moduledoc false

  use Quantum, otp_app: nil

  # def init(opts) do
  #   IO.inspect(opts)
  # end
end

defmodule OpenFn.Engine.Supervisor do
  use Supervisor

  def start_link(config) do
    name =
      config[:name] ||
        raise ArgumentError, "the :name option is required when starting OpenFn.Engine"

    config[:project_config] ||
      raise ArgumentError, ":project_config is required to start an engine."

    sup_name = Module.concat(name, "Supervisor")
    Supervisor.start_link(__MODULE__, config, name: sup_name)
  end

  def init(config) do
    # TODO: this would be the place to _receive_ compile-time config from
    # the Application module (can also be empty), and then merge in runtime config
    name = config[:name] |> IO.inspect()
    project_config = OpenFn.Config.parse!(config[:project_config])

    registry = [
      meta: [project_config: project_config],
      keys: :duplicate,
      name: Module.concat(name, "Registry")
    ]

    scheduler_jobs =
      OpenFn.Config.triggers(project_config, :cron)
      |> Enum.map(fn t ->
        {String.to_atom(t.name), [schedule: t.cron, task: {IO, :puts, [t.name]}]}
      end)
      |> Keyword.new()

    # start scheduler around here
    children = [
      {Registry, registry},
      {OpenFn.Engine.Scheduler, [id: name, name: OpenFn.Engine.Scheduler, jobs: scheduler_jobs]}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end

  def config(otp_app, module, opts) do
    conf =
      case Application.fetch_env(otp_app, module) do
        {:ok, conf} -> conf
        :error -> []
      end

    defaults = [name: opts[:name] || module]

    defaults |> Keyword.merge(conf) |> Keyword.merge(opts)
  end
end
