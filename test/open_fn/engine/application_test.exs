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

    {:ok, %OpenFn.Config{}} = Registry.meta(String.to_atom("#{TestApp}_registry"), :project_config)
  end

  test "can call handle_message without Config" do
    start_supervised!(TestApp)

    assert has_ok_results(TestApp.handle_message(%Message{body: %{"b" => 2}}))
  end

  test "fetches config from otp_app" do
    start_supervised!(AppConfigured)

    assert has_ok_results(AppConfigured.handle_message(%Message{body: %{"b" => 2}}))
  end
end
