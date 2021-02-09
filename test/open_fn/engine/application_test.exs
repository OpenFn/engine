defmodule TestApp do
  import Engine.TestUtil
  use OpenFn.Engine.Application, config: fixture(:project_config, :yaml)
end

defmodule OpenFn.Engine.Application.UnitTest do
  use ExUnit.Case, async: true

  import Engine.TestUtil

  alias OpenFn.Message

  test "can start Engine directly" do
    start_supervised!({
      OpenFn.Engine,
      config: fixture(:project_config, :yaml), name: TestApp
    })

    {:ok, %OpenFn.Config{}} = Registry.meta(TestApp.Registry, :project_config)
  end

  test "can call handle_message without Config" do
    start_supervised!(TestApp)

    assert has_ok_results(TestApp.handle_message(%Message{body: %{"b" => 2}}))
  end
end
