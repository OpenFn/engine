defmodule OpenFn.Engine.Supervisor do
  use Supervisor

  # def start_link(application, otp_app, config, name, opts) do
  #   Supervisor.start_link(
  #     __MODULE__,
  #     {application, otp_app, config, name, opts},
  #     name: name
  #   )
  # end

  def start_link(config) do
    name = config[:name] || raise ArgumentError, "the :name option is required when starting OpenFn.Engine"
    config[:project_config] || raise ArgumentError, ":project_config is required to start an engine."

    sup_name = Module.concat(name, "Supervisor")
    Supervisor.start_link(__MODULE__, config, name: sup_name)
  end

  def init(config) do
    name = config[:name]
    IO.inspect({"...", name}, label: "Engine.Supervisor.init/1")
    # {application, otp_app, config, name, opts}
    project_config = config[:project_config]

    registry = [
      meta: [project_config: setup_config(project_config)],
      keys: :duplicate,
      name: Module.concat(name, "Registry")
    ]

    children = [
      {Registry, registry}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end

  def config(otp_app, module, opts) do
    conf = case Application.fetch_env(otp_app, module) do
      {:ok, conf} -> conf
      :error -> []
    end

    defaults = [name: opts[:name] || module]

    defaults |> Keyword.merge(conf) |> Keyword.merge(opts)
  end

  def setup_config(project_config) do
    OpenFn.Config.parse!(project_config)
  end

end
