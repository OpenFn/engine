defmodule OpenFn.RunTask.UnitTest do
  use ExUnit.Case, async: false

  alias OpenFn.{Run, RunTask}

  setup do
    run = Run.new()
    run_repo_name = :test_run_repo

    start_supervised!({Task.Supervisor, [name: :task_supervisor]})

    start_supervised!(
      {OpenFn.RunRepo,
       %OpenFn.RunRepo.StartOpts{
         name: run_repo_name
       }}
    )

    %{run: run, task_supervisor: :task_supervisor, run_repo: run_repo_name}
  end

  test "can start a RunTask", %{run: run, task_supervisor: task_supervisor, run_repo: run_repo} do
    {:ok, pid} =
      RunTask.start_link(run: run, task_supervisor: task_supervisor, run_repo: run_repo)
      |> IO.inspect()

    ref = Process.monitor(pid)

    receive do
      {:DOWN, ^ref, :process, _object, :normal} -> :ok
    after
      2000 -> raise "Process should have stopped itself"
    end
  end
end
