defmodule OpenFn.RunRepo.UnitTest do
  use ExUnit.Case, async: true
  alias OpenFn.{RunRepo, Run, Job}

  setup do
    repo_name = :test_run_repo

    start_supervised!(
      {RunRepo,
       %RunRepo.StartOpts{
         name: repo_name
       }}
    )

    [repo: repo_name]
  end

  test "can store a previously executed run", %{repo: repo} do
    RunRepo.add_run(repo, run = %Run{})

    assert [run] == repo |> RunRepo.list_runs()
  end

  test "can get the most recent run for a job", %{repo: repo} do
    RunRepo.add_run(repo, %Run{job: %Job{name: "job-1"}, finished: -10})
    RunRepo.add_run(repo, run = %Run{job: job = %Job{name: "job-1"}, finished: -5})

    assert run == repo |> RunRepo.get_last_for(job)
  end
end
