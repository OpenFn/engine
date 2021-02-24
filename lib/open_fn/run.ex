defmodule OpenFn.Run do
  defstruct trigger: nil,
            job: nil,
            initial_state: nil,
            run_spec: nil,
            result: nil,
            started: nil,
            finished: nil,
            log: []

  alias OpenFn.{RunSpec, Result}

  def new(fields \\ []) do
    struct!(__MODULE__, fields)
  end

  def add_job(run, job) do
    %{run | job: job}
  end

  def add_trigger(run, trigger) do
    %{run | trigger: trigger}
  end

  def set_initial_state(run, initial_state) do
    %{run | initial_state: initial_state}
  end

  def add_run_spec(run, %RunSpec{} = run_spec) do
    %{run | run_spec: run_spec}
  end

  def set_result(run, %Result{} = result) do
    %{run | result: result}
  end

  def mark_started(run) do
    %{run | started: :erlang.monotonic_time()}
  end

  def mark_finished(run) do
    %{run | finished: :erlang.monotonic_time()}
  end

  def add_log_line(%{log: log} = run, {type, line}) do
    %{run | log: [{type, line} | log]}
  end
end
