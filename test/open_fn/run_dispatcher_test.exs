defmodule OpenFn.RunDispatcher.UnitTest do
  use ExUnit.Case, async: true

  alias OpenFn.{RunDispatcher, Run, Job, RunTask}

  setup do
    queue = :opq_test
    run_dispatcher = :test_run_dispatcher
    run_repo_name = :test_run_repo

    start_supervised!(%{id: OPQ, start: {OPQ, :init, [[name: queue]]}})
    start_supervised!({Task.Supervisor, [name: :task_supervisor]})

    start_supervised!(
      {OpenFn.RunRepo,
       %OpenFn.RunRepo.StartOpts{
         name: run_repo_name
       }}
    )

    start_supervised!(
      {RunDispatcher,
       %RunDispatcher.StartOpts{
         name: run_dispatcher,
         queue: queue,
         task_supervisor: :task_supervisor,
         run_repo: run_repo_name
       }}
    )

    run = Run.new(job: Job.new())

    %{run_dispatcher: run_dispatcher, run: run}
  end

  test "invoke_run/2", %{run: run, run_dispatcher: run_dispatcher} do
    RunDispatcher.invoke_run(run_dispatcher, run)

    Process.sleep(1500)
  end
end
