defmodule Engine.Supervisor.UnitTest do
  use ExUnit.Case, async: false

  import Engine.TestUtil
  import Crontab.CronExpression

  test "can start directly" do
    start_supervised!(
      {Engine.Supervisor,
       [
         name: "Foo",
         project_config: fixture(:project_config, :yaml),
         adaptors_path: "./priv/openfn/lib",
         otp_app: :engine
       ]}
    )

    assert Enum.count(Engine.Scheduler.jobs()) == 1
    assert Engine.Scheduler.find_job(:"trigger-4").schedule == ~e[* * * * * *]

    # :observer.start()

    # Process.sleep(2000000)

    assert true
  end
end
