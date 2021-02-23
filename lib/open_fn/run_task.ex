defmodule OpenFn.RunTask do
  use GenServer
  require Logger

  alias OpenFn.Run

  def start_link(opts) do
    Logger.debug "RunTask.start_link/1"
    GenServer.start_link(__MODULE__, opts)
  end

  def init(opts) do
    Logger.debug "RunTask.init/1"
    state = %{
      run: opts[:run],
      task_supervisor: opts[:task_supervisor],
      run_repo: opts[:run_repo],
      ref: nil
    }

    {:ok, state, {:continue, :execute}}
  end

  def handle_continue(:execute, %{task_supervisor: task_supervisor} = state) do
    Logger.debug "RunTask.handle_continue/2"
    %Task{ref: ref} = execute(self(), task_supervisor)

    {:noreply, %{state | ref: ref}}
  end

  def execute(server, task_supervisor) do
    Logger.debug "RunTask.execute/2"
    # Using async_nolink, we get messages from the Task.Supervisor which we
    # handle via handle_info/2 below
    Task.Supervisor.async_nolink(task_supervisor, fn ->
      server |> mark_started()
      runspec = server |> get_runspec()

      log_f = fn line -> GenServer.call(server, {:add_log_line, line}) end

      IO.puts("Starting task")
      {_msg, result} = OpenFn.ShellRuntime.run(runspec, log: log_f)
      IO.puts("Finishing task")
      server |> mark_finished()
      server |> set_result(result)

      result
    end)
  end

  def handle_call({:add_log_line, line}, _from, %{run: run} = state) do
    run = Run.add_log_line(run, line)

    {:reply, run, %{state | run: run}}
  end

  def handle_call({:finished?}, _from, state) do
    {:reply, Map.get(state, :run).finished, state}
  end

  def handle_call({:started?}, _from, state) do
    {:reply, Map.get(state, :run).started, state}
  end

  def handle_call(:get_runspec, _from, state) do
    {:reply, Map.get(state, :run).run_spec, state}
  end

  def handle_cast({:mark_started}, %{run: run} = state) do
    {:noreply, %{state | run: Run.mark_started(run)}}
  end

  def handle_cast({:mark_finished}, %{run: run} = state) do
    {:noreply, %{state | run: Run.mark_finished(run)}}
  end

  def handle_cast({:set_result, result}, %{run: run} = state) do
    {:noreply, %{state | run: Run.set_result(run, result)}}
  end

  def handle_cast(:done, state) do
    {:stop, :normal, state}
  end

  def done(server) do
    GenServer.cast(server, :done)
  end

  def finished?(server) do
    !!GenServer.call(server, {:finished?})
  end

  def started?(server) do
    !!GenServer.call(server, {:started?})
  end

  def get_runspec(server) do
    GenServer.call(server, :get_runspec)
  end

  def mark_started(server) do
    GenServer.cast(server, {:mark_started})
  end

  def mark_finished(server) do
    GenServer.cast(server, {:mark_finished})
  end

  def set_result(server, result) do
    GenServer.cast(server, {:set_result, result})
  end

  def terminate(reason, state) do
    Logger.debug("RunTask.terminate/2: #{inspect([reason,state])}")
  end

  def handle_info({ref, _answer}, %{ref: ref, run: run, run_repo: run_repo} = state) do
    # We don't care about the DOWN message now, so let's demonitor and flush it
    Process.demonitor(ref, [:flush])
    OpenFn.RunRepo.add_run(run_repo, run)
    done(self())

    {:noreply, %{state | ref: nil}}
  end

  def handle_info({:DOWN, _ref, :process, _pid, _reason}, state) do
    # The Task finished with an error... if it succeeds we demonitor it
    OpenFn.RunRepo.add_run(state.run_repo, state.run)
    done(self())
    {:noreply, state}
  end
end
