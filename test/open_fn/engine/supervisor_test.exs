defmodule OpenFn.Engine.Supervisor.UnitTest do
  use ExUnit.Case, async: true

  import Engine.TestUtil

  test "can start directly" do
    start_supervised!(
      {OpenFn.Engine.Supervisor,
       [name: "Foo", project_config: fixture(:project_config, :yaml), otp_app: :engine]}
    )


    # :observer.start()

    # Process.sleep(2000000)

    assert true
  end
end
