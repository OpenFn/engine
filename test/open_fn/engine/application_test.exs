defmodule TestApp do
  import Engine.TestUtil

  use OpenFn.Engine.Application,
    project_config: fixture(:project_config, :yaml),
    otp_app: :engine
end

defmodule AppConfigured do
  use OpenFn.Engine.Application, otp_app: :openfn_engine
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

    runs = OpenFn.RunRepo.list_runs(TestApp.config(:run_repo_name))

    assert has_ok_results(runs)
  end

  test "can get a list of runs without config" do
    start_supervised!(AppConfigured)

    AppConfigured.handle_message(%Message{body: %{"b" => 2}})

    Process.sleep(1000)

    runs = OpenFn.RunRepo.list_runs(AppConfigured.config(:run_repo_name))

    assert has_ok_results(runs)
  end
end
