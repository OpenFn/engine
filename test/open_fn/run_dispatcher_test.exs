defmodule OpenFn.RunDispatcher.UnitTest do
  use ExUnit.Case, async: true

  alias OpenFn.{RunDispatcher, Run, Job, RunTask}

  setup do
    Temp.track!

    queue = :opq_test
    run_dispatcher = :run_dispatcher_test
    job_state_repo_name = :test_run_repo

    start_supervised!(%{id: OPQ, start: {OPQ, :init, [[name: queue]]}})
    start_supervised!({Task.Supervisor, [name: :task_supervisor]})

    start_supervised!(
      {OpenFn.JobStateRepo,
       %OpenFn.JobStateRepo.StartOpts{
         name: job_state_repo_name,
         basedir: Temp.path!()
       }}
    )

    start_supervised!(
      {RunDispatcher,
       %RunDispatcher.StartOpts{
         name: run_dispatcher,
         queue: queue,
         task_supervisor: :task_supervisor,
         job_state_repo: job_state_repo_name
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
