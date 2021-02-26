defmodule OpenFn.JobStateRepo.UnitTest do
  use ExUnit.Case, async: true
  alias OpenFn.{JobStateRepo, Job}

  setup do
    Temp.track!()
    repo_name = :test_run_repo
    basedir = Temp.path!()

    start_supervised!(
      {JobStateRepo,
       %JobStateRepo.StartOpts{
         name: repo_name,
         basedir: basedir
       }}
    )

    %{repo: repo_name, basedir: basedir}
  end

  test "can store a previously executed job/run", %{repo: repo} do
    state_path = "/tmp/test.json"
    File.write!(state_path, "12345")

    job = Job.new(name: "my-test-job")
    JobStateRepo.register(repo, job, state_path)

    JobStateRepo.get_last_persisted_state_path(repo, job) |> File.stat!()
  end

end
