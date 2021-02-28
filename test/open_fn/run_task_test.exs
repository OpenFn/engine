defmodule OpenFn.RunTask.UnitTest do
  use ExUnit.Case, async: false

  alias OpenFn.{Run, RunTask}
  import Engine.TestUtil, only: [run_spec_fixture: 1, run_spec_fixture: 0]

  setup do
    Temp.track!()

    run = %Run{job: %OpenFn.Job{name: "test-job"}, run_spec: run_spec_fixture()}
    job_state_repo_name = :test_job_state_repo_name

    start_supervised!({Task.Supervisor, [name: :task_supervisor]})
    start_supervised!({TestServer, [name: job_state_repo_name, owner: self()]})

    %{run: run, task_supervisor: :task_supervisor, job_state_repo_name: job_state_repo_name}
  end

  test "can start a RunTask", %{
    run: run,
    task_supervisor: task_supervisor,
    job_state_repo_name: job_state_repo_name
  } do
    {:ok, pid} =
      RunTask.start_link(
        run: run,
        task_supervisor: task_supervisor,
        job_state_repo: job_state_repo_name
      )

    ref = Process.monitor(pid)

    receive do
      {:DOWN, ^ref, :process, _object, :normal} -> :ok
    after
      2000 -> raise "Process should have stopped itself"
    end

    assert_received {:run_complete, %Run{}}

    job = run.job
    final_state_path = run.run_spec.final_state_path
    assert_received {:register, ^job, ^final_state_path}


    File.write!(broken_expression = Temp.path!(), ~s[
      ...syntaxError
    ])

    {:ok, pid} =
      RunTask.start_link(
        run: new_run = %Run{run | run_spec: run_spec_fixture(expression_path: broken_expression)},
        task_supervisor: task_supervisor,
        job_state_repo: job_state_repo_name
      )


    assert_receive {:run_complete, %Run{}}, 2000
    refute_received {:register, ^job, _}
  end
end
