# Handler
# |- Has a start/1 that can do things sync
# |- can take 'context' as optional extra state for callbacks

defmodule MyCustomHandler do
  use Engine.Run.Handler

  @impl Handler
  def on_finish(_result, ctx) do
    send(ctx, :yepper)
  end
end

defmodule Engine.Run.Handler.UnitTest do
  use ExUnit.Case, async: true

  alias Engine.{Run}
  import Engine.TestUtil

  test "can retain partial logs" do
    run = %Run{
      job: %Engine.Job{name: "test-job"},
      run_spec: %{
        run_spec_fixture()
        | expression_path: write_temp!(timeout_expression(2000))
      }
    }

    result =
      MyCustomHandler.start(run.run_spec,
        context: self(),
        timeout: 1000,
        env: %{"PATH" => "./priv/openfn/runtime/node_modules/.bin:#{System.get_env("PATH")}"}
      )

    assert result.exit_reason == :killed
    assert result.log |> List.last() == "Going on break for 2000..."
  end

  @tag timeout: 5_000
  test "calls custom callbacks" do
    run = %Run{
      job: %Engine.Job{name: "test-job"},
      run_spec: run_spec_fixture()
    }

    result =
      MyCustomHandler.start(run.run_spec,
        env: %{"PATH" => "./priv/openfn/runtime/node_modules/.bin:#{System.get_env("PATH")}"},
        context: self()
      )

    assert result.exit_reason == :ok

    assert_received(:yepper)
  end

  @tag timeout: 5_000
  test "calls uses the env from a RunSpec" do
    run = %Run{
      job: %Engine.Job{name: "test-job"},
      run_spec:
        run_spec_fixture(
          env: %{"PATH" => "./priv/openfn/runtime/node_modules/.bin:#{System.get_env("PATH")}"}
        )
    }

    result =
      MyCustomHandler.start(run.run_spec,
        context: self()
      )

    assert result.exit_reason == :ok

    assert_received(:yepper)
  end
end
