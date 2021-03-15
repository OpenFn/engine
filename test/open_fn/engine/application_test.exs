defmodule TestApp do
  import Engine.TestUtil

  use OpenFn.Engine.Application,
    project_config: fixture(:project_config, :yaml),
    job_state_basedir: Temp.path!(),
    adaptors_path: "./priv/openfn/runtime/node_modules",
    otp_app: :engine
end

defmodule AppConfigured do
  use OpenFn.Engine.Application,
    otp_app: :openfn_engine,
    adaptors_path: "./priv/openfn/runtime/node_modules"
end

defmodule OpenFn.Engine.Application.UnitTest do
  use ExUnit.Case, async: false

  import Engine.TestUtil

  alias OpenFn.Message

  test "can start Engine directly" do
    start_supervised!({
      OpenFn.Engine,
      [project_config: fixture(:project_config, :yaml), name: TestApp]
    })

    {:ok, %OpenFn.Config{}} =
      Registry.meta(String.to_atom("#{TestApp}_registry"), :project_config)
  end

  test "can call handle_message without Config" do
    start_supervised!(TestApp)

    TestApp.handle_message(%Message{body: %{"b" => 2}})

    Process.sleep(1000)

    OpenFn.JobStateRepo.get_last_persisted_state_path(
      TestApp.config(:job_state_repo_name),
      %OpenFn.Job{name: "job-2"}
    )
    |> File.stat!()
  end

  test "can get a list of runs without config" do
    start_supervised!(AppConfigured)

    AppConfigured.handle_message(%Message{body: %{"b" => 2}})

    Process.sleep(1000)

    OpenFn.JobStateRepo.get_last_persisted_state_path(
      TestApp.config(:job_state_repo_name),
      %OpenFn.Job{name: "job-2"}
    )
    |> File.stat!()
  end
end
