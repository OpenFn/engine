defmodule OpenFn.Executor do
  use Task

  alias OpenFn.{RunAgent}

  defmodule StartOpts do
    @moduledoc false

    # Start Options for Quantum.Executor

    @type t :: %__MODULE__{
            executor_supervisor: GenServer.server(),
            run_agent_name: GenServer.name()
          }

    @enforce_keys [
      :executor_supervisor,
      :run_agent_name
    ]
    defstruct @enforce_keys
  end

  def start_link(%{} = opts) do
    # for when we use a ConsumerSupervisors
    Task.start_link(fn ->
      execute(opts)
    end)
  end

  # syncronous wrapper for for executing the task
  # - we start a task in the executor supervisor
  # - and then wait for a result.
  @spec execute(%StartOpts{}) :: :ok
  def execute(%{
        executor_supervisor: executor_supervisor,
        run_agent_name: run_agent_name,
      }) do
    %Task{ref: ref} = invoke(executor_supervisor, run_agent_name)

    receive do
      {^ref, any} ->
        IO.inspect(any, label: "execute/2.receive")
        RunAgent.mark_finished(run_agent_name)
        # handle DOWN
    end
  end

  def invoke(task_supervisor, run_agent_name) do
    # Start a task on our Task Supervisor, so we don't have to wait for the result.
    Task.Supervisor.async_nolink(task_supervisor, fn ->
      Process.sleep(100)

      RunAgent.mark_started(run_agent_name)
      run = RunAgent.value(run_agent_name)

      {_msg, res} =
        OpenFn.ShellRuntime.run(run.run_spec, log: &RunAgent.add_log_line(run_agent_name, &1))

      RunAgent.set_result(run_agent_name, res)
    end)
  end
end
