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
      # name(opts),
      id: "name",
      start: {__MODULE__, :start_link, [opts]},
      type: :supervisor
    }
  end

  def start_link(opts \\ []) do
    # name(opts)
    name = __MODULE__
    otp_app = Keyword.get(opts, :otp_app, __MODULE__)
    config = Keyword.get(opts, :config, %{})

    TestSupervisor.start_link(__MODULE__, otp_app, config, name, opts)
  end

  alias OpenFn.Message

  def handle_message(%Message{} = message) do
    OpenFn.Engine.handle_message(project_config!, message)
  end

  defp config(key) when is_atom(key) do
    Module.concat(__MODULE__, "Registry")
    |> Registry.meta(key)
    |> case do
      {:ok, config} -> config
      any -> any
    end
  end

  defp project_config! do
    config(:project_config) ||
      raise ArgumentError, "no :project_config configured for #{inspect(__MODULE__)}"
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
      meta: [project_config: setup_config(config)],
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

  alias OpenFn.Message

  test "can the application, and give it config" do
    start_supervised!({TestApp, config: fixture(:project_config, :yaml)})

    {:ok, %OpenFn.Config{}} = Registry.meta(TestApp.Registry, :project_config)
  end

  test "can call handle_message without Config" do
    start_supervised!({TestApp, config: fixture(:project_config, :yaml)})

    assert has_ok_results(TestApp.handle_message(%Message{body: %{"b" => 2}}))
  end
end
