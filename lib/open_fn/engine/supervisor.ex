defmodule OpenFn.Engine.Supervisor do
  use Supervisor

  def start_link(config) do
    name =
      config[:name] ||
        raise ArgumentError, "the :name option is required when starting OpenFn.Engine"

    config[:project_config] ||
      raise ArgumentError, ":project_config is required to start an engine."

    sup_name = Module.concat(name, "Supervisor")
    Supervisor.start_link(__MODULE__, config, name: sup_name)
  end

  def init(config) do
    # TODO: this would be the place to _receive_ compile-time config from
    # the Application module (can also be empty), and then merge in runtime config
    name = config[:name]
    project_config = config[:project_config]

    registry = [
      meta: [project_config: OpenFn.Config.parse!(project_config)],
      keys: :duplicate,
      name: Module.concat(name, "Registry")
    ]

    children = [
      {Registry, registry}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end

  def config(otp_app, module, opts) do
    conf =
      case Application.fetch_env(otp_app, module) do
        {:ok, conf} -> conf
        :error -> []
      end

    defaults = [name: opts[:name] || module]

    defaults |> Keyword.merge(conf) |> Keyword.merge(opts)
  end
end
