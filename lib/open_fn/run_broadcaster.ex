defmodule OpenFn.RunBroadcaster do
  @moduledoc """
  Responsible for taking a Message, CronTrigger or FlowTrigger and matching
  it to a Job.
  """
  use GenServer

  alias OpenFn.{Config, Matcher, RunDispatcher, Run, JobStateRepo}

  defmodule StartOpts do
    @moduledoc false

    @type t :: %__MODULE__{
            config: Config.t(),
            run_dispatcher: GenServer.name(),
            job_state_repo: GenServer.name(),
            name: GenServer.name()
          }

    @enforce_keys [:name, :run_dispatcher, :job_state_repo]
    defstruct @enforce_keys ++ [config: %Config{}]
  end

  defmodule State do
    @moduledoc false

    @type t :: %__MODULE__{
            config: Config.t(),
            run_dispatcher: GenServer.name(),
            job_state_repo: GenServer.name(),
            runs: []
          }

    @enforce_keys [:run_dispatcher, :job_state_repo]
    defstruct @enforce_keys ++ [config: %Config{}, runs: []]
  end

  def start_link(%StartOpts{} = opts) do
    state =
      opts
      |> Map.take([:config, :run_dispatcher, :job_state_repo])

    GenServer.start_link(__MODULE__, state, name: opts.name)
  end

  def init(opts) do
    {:ok, struct!(State, opts)}
  end

  def handle_call({:handle_message, message}, _from, state) do
    %{config: config, run_dispatcher: run_dispatcher} = state

    triggers = Matcher.get_matches(Config.triggers(config, :criteria), message)

    runs =
      Config.jobs_for(config, triggers)
      |> Enum.map(fn job ->
        Run.new(job: job, initial_state: %{"data" => message.body})
      end)

    runs |> Enum.each(&RunDispatcher.invoke_run(run_dispatcher, &1))

    {:reply, runs, state}
  end

  def handle_call({:handle_trigger, trigger}, _from, state) do
    %{config: config, run_dispatcher: run_dispatcher} = state

    runs =
      Config.jobs_for(config, [trigger])
      |> Enum.map(fn job ->
        last_state_path = JobStateRepo.get_last_persisted_state_path(state.job_state_repo, job)

        source_state =
          case File.stat(last_state_path) do
            {:ok, _} ->
              # assume a file path
              {:file, last_state_path}

            {:error, _} ->
              # file not found, send an empty map to be serialised to json
              %{}
          end

        # TODO: credentials
        next_state = %{}

        initial_state = merge_states([source_state, next_state])

        Run.new(job: job, trigger: trigger, initial_state: initial_state)
      end)
      |> Enum.map(&RunDispatcher.invoke_run(run_dispatcher, &1))

    {:reply, runs, state}
  end

  def handle_call({:process_run, %Run{job: job} = run}, _from, state) do
    %{config: config, run_dispatcher: run_dispatcher} = state

    runs =
      Config.job_triggers_for(config, job)
      |> Enum.filter(fn {_job, trigger} ->
        (run.result.exit_code == 0 && trigger.success) || (run.result > 0 && trigger.failure)
      end)
      |> Enum.map(fn {triggered_job, trigger} ->
        # Get the final_state from the Run that triggered this.
        last_state_path = JobStateRepo.get_last_persisted_state_path(state.job_state_repo, job)

        source_state =
          case File.stat(last_state_path) do
            {:ok, _} ->
              # assume a file path
              {:file, last_state_path}

            {:error, _} ->
              # file not found, send an empty map to be serialised to json
              %{}
          end

        # TODO: credentials
        next_state = %{}

        initial_state = merge_states([source_state, next_state])

        Run.new(job: triggered_job, trigger: trigger, initial_state: initial_state)
      end)
      |> Enum.map(&RunDispatcher.invoke_run(run_dispatcher, &1))

    {:reply, runs, state}
  end

  defp merge_states(states) when is_list(states) do
    states
    |> Enum.map(fn state ->
      case state do
        {:file, path} -> File.read!(path) |> Jason.decode!()
        any -> any
      end
    end)
    |> Enum.reduce(fn state, acc -> Map.merge(acc, state) end)
  end

  def handle_message(server, message) do
    GenServer.call(server, {:handle_message, message})
  end

  def handle_trigger(server, trigger) do
    GenServer.call(server, {:handle_trigger, trigger})
  end

  def process(server, %Run{} = run) do
    GenServer.call(server, {:process_run, run})
  end
end
