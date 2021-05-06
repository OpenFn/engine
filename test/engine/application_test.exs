defmodule TestApp do
  import Engine.TestUtil

  use Engine.Application,
    project_config: fixture(:project_config, :yaml),
    job_state_basedir: Temp.path!(),
    adaptors_path: "./priv/openfn/runtime",
    otp_app: :engine
end

defmodule AppConfigured do
  use Engine.Application,
    otp_app: :engine,
    adaptors_path: "./priv/openfn/runtime"
end

defmodule Engine.Application.UnitTest do
  use ExUnit.Case, async: false

  import Engine.TestUtil

  alias Engine.Message
  @moduletag timeout: 10_000

  test "can start Engine directly" do
    start_supervised!({
      Engine,
      [project_config: fixture(:project_config, :yaml), name: TestApp]
    })

    {:ok, %Engine.Config{}} =
      Registry.meta(String.to_atom("#{TestApp}_registry"), :project_config)
  end

  test "can call handle_message without Config" do
    start_supervised!(TestApp)

    TestApp.handle_message(%Message{body: %{"b" => 2}})

    Process.sleep(2000)

    Engine.JobStateRepo.get_last_persisted_state_path(
      TestApp.config(:job_state_repo_name),
      %Engine.Job{name: "job-2"}
    )
    |> File.stat!()
  end

  test "can get a list of runs without config" do
    start_supervised!(AppConfigured)

    AppConfigured.handle_message(%Message{body: %{"b" => 2}})

    Process.sleep(1000)

    Engine.JobStateRepo.get_last_persisted_state_path(
      TestApp.config(:job_state_repo_name),
      %Engine.Job{name: "job-2"}
    )
    |> File.stat!()
  end
end
