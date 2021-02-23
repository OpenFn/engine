defmodule OpenFn.RunRepo do
  @moduledoc """
  Responsible for storing runs
  """
  use GenServer
  require Logger

  alias OpenFn.{Run, Job}

  defmodule StartOpts do
    @moduledoc false

    @type t :: %__MODULE__{
            name: GenServer.name()
          }

    @enforce_keys [:name]
    # ++ [config: %Config{}]
    defstruct @enforce_keys
  end

  defmodule State do
    @moduledoc false

    # Start Options for Quantum.Executor

    @type t :: %__MODULE__{
            runs: []
          }

    # @enforce_keys [:run_dispatcher]
    # @enforce_keys ++ [config: %Config{}, runs: []]
    defstruct runs: []
  end

  def start_link(%StartOpts{} = opts) do
    state =
      opts
      |> Map.take([:config, :run_dispatcher])

    GenServer.start_link(__MODULE__, state, name: opts.name)
  end

  def init(opts) do
    {:ok, struct!(State, opts)}
  end

  def handle_call({:add_run, run}, _from, state) do
    Logger.debug("Adding run to repo.")
    {:reply, :ok, %{state | runs: [run | state.runs]}}
  end

  def handle_call({:list_runs}, _from, state) do
    {:reply, state.runs, state}
  end

  def handle_call({:get_last_for, %Job{name: job_name}}, _from, state) do
    last_run =
      state.runs
      |> Enum.filter(fn run -> run.job.name == job_name && run.finished end)
      |> Enum.sort_by(&Map.get(&1, :finished), :desc)
      |> hd

    {:reply, last_run, state}
  end

  def add_run(server, %Run{} = run), do: GenServer.call(server, {:add_run, run})

  def list_runs(server), do: GenServer.call(server, {:list_runs})

  def get_last_for(server, %Job{} = job), do: GenServer.call(server, {:get_last_for, job})
end
