# Handler
# |- Has a start/1 that can do things sync
# |- can take 'context' as optional extra state for callbacks

defmodule MyCustomHandler do
  use OpenFn.Run.Handler

  @impl Handler
  def on_finish(ctx) do
    send(ctx, :yepper)
  end
end

defmodule OpenFn.Run.Handler.UnitTest do
  use ExUnit.Case, async: true

  alias OpenFn.{Run}
  import Engine.TestUtil

  test "can retain partial logs" do
    run = %Run{
      job: %OpenFn.Job{name: "test-job"},
      run_spec: %{
        run_spec_fixture()
        | expression_path: write_temp!(timeout_expression(700))
      }
    }

    result = MyCustomHandler.start(run, context: self(), timeout: 600)

    assert result.exit_reason == :killed
    assert result.log |> List.last() == "Going on break for 700..."
  end


  @tag timeout: 5_000
  test "calls custom callbacks" do
    run = %Run{
      job: %OpenFn.Job{name: "test-job"},
      run_spec: run_spec_fixture()
    }

    MyCustomHandler.start(run, context: self())

    assert_received(:yepper)
  end
end
