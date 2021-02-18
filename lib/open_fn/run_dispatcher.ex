defmodule OpenFn.RunDispatcher do
  @moduledoc """
  Server to coordinate executing Runs with their associated RunAgents

  In order to start RunDispatcher, it requires:

  - **name**
    The name of the process
  - **run_registry**
    The name of the run registry used to register the resulting RunAgent
  """
  defmodule StartOpts do
    @type t :: %__MODULE__{
            name: GenServer.name(),
            run_registry: GenServer.name()
          }

    @enforce_keys [:name, :run_registry]
    defstruct @enforce_keys
  end

  use GenServer

  alias OpenFn.{RunAgent, Executor, RunSpec, Run}

  def start_link(%StartOpts{} = opts) do
    GenServer.start_link(__MODULE__, opts, name: opts.name)
  end

  @spec init(any) :: {:ok, any}
  def init(init_arg) do
    IO.puts("RunDispatcher started")
    {:ok, init_arg}
  end

  def handle_call({:invoke_run, run}, _from, state) do
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

    run_agent = run_agent_name(state, run)
    RunAgent.start_link(%RunAgent.StartOpts{name: run_agent, run: run})

    Executor.execute(%Executor.StartOpts{
      executor_supervisor: :executor_supervisor,
      run_agent_name: run_agent
    })

    {:reply, RunAgent.value(run_agent), state}
  end

  def invoke_run(server, run) do
    server |> GenServer.call({:invoke_run, run})
  end

  defp run_agent_name(%{run_registry: run_registry}, run) do
    {:via, Registry, {run_registry, run.job.name}}
  end
end
