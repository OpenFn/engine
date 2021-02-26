defmodule OpenFn.RunDispatcher.UnitTest do
  use ExUnit.Case, async: true

  alias OpenFn.{RunDispatcher, Run, Job, RunTask}
  import Engine.TestUtil, only: [run_spec_fixture: 0]

  setup do
    Temp.track!()

    queue = :opq_test
    run_dispatcher = :run_dispatcher_test
    run_broadcaster = :run_dispatcher_test_broadcaster
    job_state_repo_name = :test_run_repo

    start_supervised!(%{id: OPQ, start: {OPQ, :init, [[name: queue]]}})
    start_supervised!({Task.Supervisor, [name: :task_supervisor]})

    start_supervised!(%{
      id: :fake_run_broadcaster,
      start: {TestServer, :start_link, [[name: run_broadcaster, owner: self()]]}
    })

    start_supervised!(%{
      id: :fake_job_repo,
      start: {TestServer, :start_link, [[name: job_state_repo_name, owner: self()]]}
    })

    start_supervised!(
      {RunDispatcher,
       %RunDispatcher.StartOpts{
         name: run_dispatcher,
         queue: queue,
         task_supervisor: :task_supervisor,
         job_state_repo: job_state_repo_name,
         run_broadcaster: run_broadcaster
       }}
    )

    run = %Run{job: %OpenFn.Job{name: "test-job"}, run_spec: run_spec_fixture()}

    %{run_dispatcher: run_dispatcher, run: run}
  end

  test "invoke_run/2", %{run: run, run_dispatcher: run_dispatcher} do
    RunDispatcher.invoke_run(run_dispatcher, run)

    assert_receive {:process_run, %Run{}}, 1500
    assert_receive {:register, _, _}, 1500
  end
end