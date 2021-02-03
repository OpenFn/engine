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
    body = """
    {"a": 1}
    """

    expression = """
      alterState(state => {
        console.log("dfgdfgdfgdfgdf")
        console.log(state)
        return state
      })
    """

    {:ok, %Result{} = result} =
      OpenFn.Engine.execute_sync(%Message{body: body}, %Job{
        expression: expression,
        language_pack: "./\\@openfn/language-common.Adaptor"
      })

    assert result.exit_code == 0
    IO.inspect(result.log)
    File.read!(result.final_state_path) |> IO.inspect()
  end

  test "handle_message/2" do
    body = """
    {"a": 1}
    """

    {:ok, results} = OpenFn.Engine.handle_message(%Config{}, %Message{body: body})

    IO.inspect(results)
    # File.read!(result.final_state_path) |> IO.inspect()
  end

  test "process_sync/2" do
    body = """
    {"a": 1}
    """

    expression = """
      alterState(state => console.log(state))
    """

    OpenFn.Engine.process_sync(%{body: body})
  end
end
