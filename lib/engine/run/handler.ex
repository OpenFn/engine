defmodule Engine.Run.Handler do
  alias Engine.{RunSpec}

  @type t :: module

  defmodule State do
    @type t :: %__MODULE__{
            task_supervisor: pid(),
            agent_supervisor: pid(),
            log_agent: pid(),
            log_agent_ref: reference(),
            run_task: Task.t(),
            context: any()
          }

    defstruct [
      :task_supervisor,
      :agent_supervisor,
      :log_agent,
      :log_agent_ref,
      :run_task,
      :context
    ]
  end

  @doc false
  defmacro __using__(_opts) do
    quote location: :keep do
      alias Engine.Run.Handler
      @behaviour Handler

      @impl Handler
      def start(run_spec, opts \\ []) do
        {:ok, task_supervisor} = Task.Supervisor.start_link()
        {:ok, agent_supervisor} = DynamicSupervisor.start_link(strategy: :one_for_one)
        {:ok, log_agent} = DynamicSupervisor.start_child(agent_supervisor, {Engine.LogAgent, []})
        log_agent_ref = Process.monitor(log_agent)

        context = opts[:context] || nil

        rambo_opts =
          Keyword.take(opts, [:timeout])
          |> Keyword.merge(
            log: &log_callback(log_agent, context, &1),
            env: env(run_spec, opts)
          )

        run_task =
          Task.Supervisor.async_nolink(task_supervisor, fn ->
            __MODULE__.on_start(context)

            {_msg, result} = Engine.ShellRuntime.run(run_spec, rambo_opts)

            result
          end)

        wait(%State{
          task_supervisor: task_supervisor,
          agent_supervisor: agent_supervisor,
          log_agent: log_agent,
          log_agent_ref: log_agent_ref,
          run_task: run_task,
          context: context
        })
      end

      @impl Handler
      def log_callback(log_agent, context, args) do
        Engine.LogAgent.process_chunk(log_agent, args)
        |> Enum.each(&__MODULE__.on_log_line(&1, context))

        false
      end

      defp wait(
             %State{
               run_task: %Task{ref: run_task_ref},
               log_agent_ref: log_agent_ref
             } = state
           ) do
        receive do
          # RunTask finished
          {^run_task_ref, result} ->
            __MODULE__.on_finish(result, state.context)
            # We don't care about the DOWN message now, so let's demonitor and flush it
            Process.demonitor(run_task_ref, [:flush])
            Process.demonitor(log_agent_ref, [:flush])
            log = Engine.LogAgent.lines(state.log_agent)
            stop(state)
            %{result | log: log}

          {:DOWN, ^run_task_ref, :process, _pid, _exp} ->
            stop(state)
            # This means that the task, and therefore Rambo finished without
            # either a value or an exception, in all reasonable circumstances
            # this should not be reached.
            raise "ShellRuntime task exited without a value"

          {:DOWN, ^log_agent_ref, :process, _pid, _exp} ->
            stop(state)
            # Something when wrong in the logger, when/if this gets reached
            # we need to decide what we want to be done.
            raise "Logging agent process ended prematurely"
        end
      end

      def stop(%State{
            task_supervisor: task_supervisor,
            agent_supervisor: agent_supervisor
          }) do
        Supervisor.stop(task_supervisor)
        DynamicSupervisor.stop(agent_supervisor)
      end

      defdelegate env(run_spec, opts), to: Handler
      defdelegate on_start(context), to: Handler
      defdelegate on_log_line(line, context), to: Handler
      defdelegate on_finish(result, context), to: Handler

      defoverridable Handler
    end
  end

  @doc """
  The entrypoint for executing a run.
  """
  @callback start(run_spec :: %RunSpec{}, opts :: []) :: Engine.Result.t()

  @doc """
  Called with context, if any - when the Run has been started.
  """
  @callback on_start(context :: any()) :: any
  @callback on_log_line(line :: list(binary()), context :: any()) :: any
  @callback on_finish(result :: Engine.Result.t(), context :: any()) :: any
  @callback log_callback(agent :: pid(), context :: any(), args :: any()) :: false

  def on_start(_context), do: :noop
  def on_log_line(_line, _context), do: :noop
  def on_finish(_result, _context), do: :noop

  @callback env(run_spec :: %RunSpec{}, opts :: []) :: %{binary() => binary()}

  def env(run_spec, opts) do
    %{"NODE_PATH" => run_spec.adaptors_path}
    |> Map.merge(Keyword.get(opts, :env, %{}))
  end
end
