defmodule OpenFn.RunDispatcher do
  @moduledoc """
  Server to coordinate executing Runs with their associated RunAgents

  In order to start RunDispatcher, it requires:

  - **name**
    The name of the process
  """
  defmodule StartOpts do
    @type t :: %__MODULE__{
            name: GenServer.name(),
            queue: GenServer.name(),
            task_supervisor: GenServer.name(),
            job_state_repo: GenServer.name(),
            run_broadcaster: GenServer.name(),
            temp_opts: Map.t()
          }

    @enforce_keys [:name, :queue, :task_supervisor, :job_state_repo, :run_broadcaster]
    defstruct @enforce_keys ++ [temp_opts: %{}]
  end

  defmodule GenericHandler do
    use OpenFn.Run.Handler
  end

  use GenServer
  require Logger

  alias OpenFn.{RunSpec, Run, RunBroadcaster, JobStateRepo}

  def start_link(%StartOpts{} = opts) do
    GenServer.start_link(__MODULE__, opts, name: opts.name)
  end

  @spec init(any) :: {:ok, any}
  def init(opts) do
    if basedir = Map.get(opts.temp_opts, :basedir) do
      File.mkdir_p!(basedir)
    end

    {:ok, opts}
  end

  def handle_call({:invoke_run, run}, _from, state) do
    Logger.debug("RunDispatcher.invoke_run")

    run = Run.add_run_spec(run, prepare_runspec(run, state.temp_opts))

    OPQ.enqueue(state.queue, fn ->
      run = Run.mark_started(run)
      result = GenericHandler.start(run.run_spec)

      if result.exit_code == 0 do
        JobStateRepo.register(state.job_state_repo, run.job, run.run_spec.final_state_path)
      end

      RunBroadcaster.process(
        state.run_broadcaster,
        Run.mark_finished(run) |> Run.set_result(result)
      )
    end)

    {:reply, :ok, state}
  end

  defp generate_path(name, temp_opts) do
    [prefix, suffix] = String.split(name, ".")

    {:ok, path} =
      Temp.path(
        %{prefix: prefix, suffix: "." <> suffix}
        |> Map.merge(temp_opts)
      )

    Path.absname(path)
  end

  defp prepare_runspec(%Run{} = run, temp_opts) do
    # TODO: set base_dir option to save the files to somewhere in the project
    final_state_path = generate_path("final_state.json", temp_opts)
    expression_path = generate_path("expression.js", temp_opts)

    # TODO: this || makes me sad, refactor
    state_path =
      case run.initial_state || %{} do
        {:file, path} ->
          path

        state when is_map(state) ->
          state_path = generate_path("state.json", temp_opts)
          File.write!(state_path, Jason.encode!(run.initial_state))
          state_path
      end

    File.write!(expression_path, run.job.expression || "")

    %RunSpec{
      state_path: state_path,
      final_state_path: final_state_path,
      expression_path: expression_path,
      adaptor: run.job.adaptor
    }
  end

  def invoke_run(server, run) do
    server |> GenServer.call({:invoke_run, run})
  end
end
