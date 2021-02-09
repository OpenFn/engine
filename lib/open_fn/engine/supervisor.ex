defmodule OpenFn.Engine.Supervisor do
  use Supervisor

  # def start_link(application, otp_app, config, name, opts) do
  #   Supervisor.start_link(
  #     __MODULE__,
  #     {application, otp_app, config, name, opts},
  #     name: name
  #   )
  # end

  def start_link(opts) do
    IO.inspect(opts, label: "Engine.Supervisor.start_link/1")
    name =
      opts[:name] ||
        raise ArgumentError, "the :name option is required when starting OpenFn.Engine"

    sup_name = Module.concat(name, "Supervisor")
    Supervisor.start_link(__MODULE__, opts, name: sup_name)
  end

  def init(opts) do
    # {application, otp_app, config, name, opts}
    name = opts[:name]
    config = opts[:config]

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
