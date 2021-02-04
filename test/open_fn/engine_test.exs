defmodule OpenFn.Engine.UnitTest do
  use ExUnit.Case, async: true
  doctest OpenFn.Engine

  alias OpenFn.{Message, Job, Result, Config}

  describe "child_spec/1" do
    test "expects a name" do
      {:error, {{:EXIT, {exception, _}}, _}} = start_supervised({OpenFn.Engine, []})

      assert Exception.message(exception) ==
               "the :name option is required when starting OpenFn.Engine"
    end
  end

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
    [{:ok, result}] = OpenFn.Engine.handle_message(config, %Message{body: body})

    IO.inspect(result)
    # File.read!(result.final_state_path) |> IO.inspect()
  end
end
