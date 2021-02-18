defmodule OpenFn.Engine.UnitTest do
  use ExUnit.Case, async: true
  doctest OpenFn.Engine

  alias OpenFn.{Message, Job, Result, Config}

  test "execute_sync/2" do
    body = Jason.decode!(~s({"a": 1}))

    expression = """
      alterState(state => {
        return state
      })
    """

    {:ok, %Result{} = result} =
      OpenFn.Engine.execute_sync(%Message{body: body}, %Job{
        expression: expression,
        language_pack: "@openfn/language-common"
      })

    assert result.exit_code == 0
    assert File.read!(result.final_state_path) == "{\n  \"a\": 1\n}"
  end

  test "handle_message/2" do
    body = Jason.decode!(~s({"a": 1}))

    config_yaml = ~S"""
    jobs:
      job-1:
        expression: none
        language_pack: @openfn/language-common
        trigger: trigger-2
      job-2:
        expression: none
        language_pack: @openfn/language-common
        trigger: trigger-3
      job-3:
        expression: none
        language_pack: @openfn/language-common
        trigger: trigger-3

    triggers:
      trigger-2:
        criteria: '{"a":1}'
      trigger-3:
        criteria: '{"b":2}'
    """

    {:ok, config} = Config.parse(config_yaml)
    [run] = OpenFn.Engine.handle_message(config, %Message{body: body})

    assert File.read!(run.result.final_state_path) == "{\n  \"a\": 1\n}"
  end

  test "handle_trigger/2" do
    body = Jason.decode!(~s({"a": 1}))

    config_yaml = ~S"""
    jobs:
      job-3:
        expression: none
        language_pack: @openfn/language-common
        trigger: trigger-2

    triggers:
      trigger-2:
        cron: '* * * * *'
    """

    {:ok, config} = Config.parse(config_yaml)
    trigger = hd(Config.triggers(config, :cron))
    [{:ok, result}] = OpenFn.Engine.handle_trigger(config, trigger)

    assert File.read!(result.final_state_path) == "{}"
  end
end
