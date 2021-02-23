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
            run_repo: GenServer.name()
          }

    @enforce_keys [:name, :queue, :task_supervisor, :run_repo]
    defstruct @enforce_keys
  end

  use GenServer
  require Logger

  alias OpenFn.{RunTask, RunSpec, Run}

  def start_link(%StartOpts{} = opts) do
    GenServer.start_link(__MODULE__, opts, name: opts.name)
  end

  @spec init(any) :: {:ok, any}
  def init(init_arg) do
    IO.puts("RunDispatcher started")
    {:ok, init_arg}
  end

  def handle_call({:invoke_run, run}, _from, state) do
    Logger.debug("RunDispatcher.invoke_run")
    {:ok, state_path} = Temp.path(%{prefix: "state", suffix: ".json"})
    {:ok, final_state_path} = Temp.path(%{prefix: "final_state", suffix: ".json"})
    {:ok, expression_path} = Temp.path(%{prefix: "expression", suffix: ".js"})

    File.write!(state_path, Jason.encode!(run.initial_state))
    File.write!(expression_path, run.job.expression || "")

    run =
      Run.add_run_spec(run, %RunSpec{
        state_path: state_path,
        final_state_path: final_state_path,
        expression_path: expression_path,
        language_pack: run.job.language_pack
      })

    OPQ.enqueue(state.queue, fn ->
      {:ok, pid} =
        RunTask.start_link(
          run: run,
          task_supervisor: :task_supervisor,
          run_repo: state.run_repo

        )

      Process.monitor(pid)

      # Intentionally wait or else or we'll dispatch too many Runs
      receive do
        {:DOWN, _ref, :process, _pid, :normal} ->
          nil
      end
    end) |> IO.inspect

    {:reply, :ok, state}
  end

  def invoke_run(server, run) do
    server |> GenServer.call({:invoke_run, run})
  end
end
