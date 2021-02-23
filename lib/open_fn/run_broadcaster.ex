defmodule OpenFn.RunBroadcaster do
  @moduledoc """
  Responsible for taking a Message, CronTrigger or FlowTrigger and matching
  it to a Job.
  """
  use GenServer

  alias OpenFn.{Config, Matcher, RunDispatcher, Run, RunRepo}

  defmodule StartOpts do
    @moduledoc false

    @type t :: %__MODULE__{
            config: Config.t(),
            run_dispatcher: GenServer.name(),
            run_repo: GenServer.name(),
            name: GenServer.name()
          }

    @enforce_keys [:name, :run_dispatcher, :run_repo]
    defstruct @enforce_keys ++ [config: %Config{}]
  end

  defmodule State do
    @moduledoc false

    @type t :: %__MODULE__{
            config: Config.t(),
            run_dispatcher: GenServer.name(),
            run_repo: GenServer.name(),
            runs: [],
          }

    @enforce_keys [:run_dispatcher, :run_repo]
    defstruct @enforce_keys ++ [config: %Config{}, runs: []]
  end

  def start_link(%StartOpts{} = opts) do
    state =
      opts
      |> Map.take([:config, :run_dispatcher, :run_repo])

    GenServer.start_link(__MODULE__, state, name: opts.name)
  end

  def init(opts) do
    {:ok, struct!(State, opts)}
  end

  def handle_call({:handle_message, message}, _from, state) do
    %{config: config, run_dispatcher: run_dispatcher} = state

    triggers = Matcher.get_matches(Config.triggers(config, :criteria), message)

    runs = Config.jobs_for(config, triggers)
    |> Enum.map(fn job ->
      Run.new(job: job, initial_state: message.body)
    end)
    |> Enum.map(&RunDispatcher.invoke_run(run_dispatcher, &1))

    {:reply, runs, state}
  end

  def handle_call({:handle_trigger, trigger}, _from, state) do
    %{config: config, run_dispatcher: run_dispatcher} = state

    runs = Config.jobs_for(config, [trigger])
    |> Enum.map(fn job ->
      last_run = RunRepo.get_last_for(state.run_repo, job)

      initial_state = case last_run do
        %Run{result: %{final_state_path: path}} when is_binary(path) ->
          # assume a file path
          {:file, path}
        _any ->
          %{}
      end

      Run.new(job: job, trigger: trigger, initial_state: initial_state)
    end)
    |> Enum.map(&RunDispatcher.invoke_run(run_dispatcher, &1))

    {:reply, runs, state}
  end

  def handle_call({:add_run, run}, _from, state) do
    {:reply, :ok, %{state | runs: [run | state.runs]}}
  end

  def handle_call({:list_runs}, _from, state) do
    {:reply, state.runs, state}
  end

  def handle_message(server, message) do
    GenServer.call(server, {:handle_message, message})
  end

  def handle_trigger(server, trigger) do
    GenServer.call(server, {:handle_trigger, trigger})
  end
end
