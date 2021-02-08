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
    registry = [
      meta: [config: setup_config(config)],
      keys: :duplicate,
      name: Module.concat(name, "Registry")
    ]

    children = [
      {Registry, registry}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end

  def setup_config(config) do
    OpenFn.Config.parse!(config)
  end
end

defmodule OpenFn.Engine.Application.UnitTest do
  use ExUnit.Case, async: true

  import Engine.TestUtil

  test "" do
    start_supervised!({TestApp, config: fixture(:project_config, :yaml)}) |> IO.inspect

    {:ok, %OpenFn.Config{}} = Registry.meta(TestApp.Registry, :config)
  end
end
