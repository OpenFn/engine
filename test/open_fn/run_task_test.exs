defmodule OpenFn.RunTask.UnitTest do
  use ExUnit.Case, async: false

  alias OpenFn.{Run, RunTask}

  setup do
    Temp.track!()

    run = Run.new()
    job_state_repo_name = :test_job_state_repo_name

    start_supervised!({Task.Supervisor, [name: :task_supervisor]})

    start_supervised!(
      {OpenFn.JobStateRepo,
       %OpenFn.JobStateRepo.StartOpts{
         name: job_state_repo_name,
         basedir: Temp.path!()
       }}
    )

    %{run: run, task_supervisor: :task_supervisor, job_state_repo_name: job_state_repo_name}
  end

  test "can start a RunTask", %{run: run, task_supervisor: task_supervisor, job_state_repo_name: job_state_repo_name} do
    {:ok, pid} =
      RunTask.start_link(run: run, task_supervisor: task_supervisor, job_state_repo: job_state_repo_name)
      |> IO.inspect()

    ref = Process.monitor(pid)

    receive do
      {:DOWN, ^ref, :process, _object, :normal} -> :ok
    after
      2000 -> raise "Process should have stopped itself"
    end
  end
end
