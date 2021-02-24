defmodule OpenFn.Engine.Supervisor.UnitTest do
  use ExUnit.Case, async: false

  import Engine.TestUtil
  import Crontab.CronExpression

  test "can start directly" do
    start_supervised!(
      {OpenFn.Engine.Supervisor,
       [
         name: "Foo",
         project_config: fixture(:project_config, :yaml),
         otp_app: :engine
       ]}
    )

    assert Enum.count(OpenFn.Engine.Scheduler.jobs()) == 1
    assert OpenFn.Engine.Scheduler.find_job(:"trigger-4").schedule == ~e[* * * * * *]

    # :observer.start()

    # Process.sleep(2000000)

    assert true
  end
end
