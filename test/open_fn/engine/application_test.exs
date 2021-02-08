# defmodule MyApp.Application do
#   use Commanded.Application,
#     otp_app: :my_app,
#     event_store: [
#       adapter: Commanded.EventStore.Adapters.EventStore,
#       event_store: MyApp.EventStore
#     ],
#     pubsub: :local,
#     registry: :local
#   router(MyApp.Router)
# end

defmodule TestApp do
  def child_spec(opts) do
    %{
      id: "name", #name(opts),
      start: {__MODULE__, :start_link, [opts]},
      type: :supervisor
    }
  end

  def start_link(opts \\ []) do
    name = __MODULE__ #name(opts)
    otp_app = Keyword.get(opts, :otp_app, __MODULE__)
    config = Keyword.get(opts, :config, %{})

    TestSupervisor.start_link(__MODULE__, otp_app, config, name, opts)
  end
end

defmodule TestSupervisor do
  use Supervisor

  def start_link(application, otp_app, config, name, opts) do
    Supervisor.start_link(
      __MODULE__,
      {application, otp_app, config, name, opts},
      name: name
    )
  end

  def init({application, otp_app, config, name, opts}) do
    children = [
      # {Foo, foo_spec}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end

end

defmodule OpenFn.Engine.Application.UnitTest do
  use ExUnit.Case, async: true

  test "" do
    start_supervised!({TestApp, config: nil})
    assert true
  end
end
