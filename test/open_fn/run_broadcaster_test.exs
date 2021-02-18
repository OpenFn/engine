defmodule OpenFn.RunBroadcaster.UnitTest do
  use ExUnit.Case, async: true
  alias OpenFn.{RunBroadcaster, Config, CriteriaTrigger, Job}

  test "matches up a CriteriaTrigger to a message" do
    config =
      Config.new(
        triggers: [%CriteriaTrigger{name: "test", criteria: %{"a" => 1}}],
        jobs: [%Job{name: "test-job", trigger: "test"}]
      )

    start_supervised!(
      {RunBroadcaster,
       %RunBroadcaster.StartOpts{
         name: :test_run_broadcaster,
         run_dispatcher: :test_run_dispatcher,
         config: config
       }}
    )

    start_supervised!(
      {TestServer, [name: :test_run_dispatcher, owner: self()]}
    )

    RunBroadcaster.handle_message(
      :test_run_broadcaster,
      %{body: %{"a" => 1}}
    )

    got_a_run = receive do
      {:invoke_run, %OpenFn.Run{}} ->
        true
      _ -> false
    end

    assert got_a_run
  end
end
