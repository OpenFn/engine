defmodule Engine.Adaptor.Service do
  @moduledoc """
  The Adaptor Service is use to query and install adaptors in order to run jobs.

  It is started up with the Engine application is started.

  ## Configuration

  The service requires at least `:adaptors_path`, which is used to both query
  which adaptors are installed and when to install new adaptors.

  Another optional setting is: `:repo`, which must point at a module that will be
  used to do the querying and installing.
  """
  defmodule State do
    @enforce_keys [:adaptors_path]
    defstruct [:adaptors_path, :name, repo: Engine.Adaptor.Repo]
  end

  use GenServer

  def start_link(opts) do
    name = Keyword.get(opts, :name, __MODULE__)

    GenServer.start_link(__MODULE__, Map.new(opts), name: name)
  end

  @impl GenServer
  def init(opts) do
    {:ok, struct!(State, opts)}
  end

  @impl GenServer
  def handle_call(
        {:installed?, package_name, version},
        _from,
        state = %{repo: repo, adaptors_path: adaptors_path}
      ) do
    found =
      repo.list_local(adaptors_path)
      |> adaptor_exists?({package_name, version})

    {:reply, found, state}
  end

  def handle_call(
        {:install, package_name, version},
        _from,
        state = %{repo: repo, adaptors_path: adaptors_path}
      ) do
    :ok = repo.install(build_aliased_name(package_name, version), adaptors_path)

    {:reply, :ok, state}
  end

  def handle_call(
        {:ensure_installed, package_name, version},
        _from,
        state = %{repo: repo, adaptors_path: adaptors_path}
      ) do
    found =
      repo.list_local(adaptors_path)
      |> adaptor_exists?({package_name, version})

    if !found do
      :ok = repo.install(build_aliased_name(package_name, version), adaptors_path)
    end

    {:reply, :ok, state}
  end

  def installed?(server, package_name, version) do
    server |> GenServer.call({:installed?, package_name, version})
  end

  def install(server, package_name, version) do
    server |> GenServer.call({:install, package_name, version})
  end

  def ensure_installed!(server, package) do
    server |> GenServer.call({:ensure_installed, package, nil})
  end

  def build_aliased_name(package, version \\ nil)

  def build_aliased_name(package, version) when is_nil(version) do
    package
    |> String.split("@")
    |> case do
      [_, name, "latest"] ->
        "@#{name}-latest@npm:@#{name}"

      [_, name, version] ->
        "@#{name}-v#{version}@npm:@#{name}@#{version}"

      [_, _name] ->
        package

      _ ->
        raise ArgumentError, "Only npm style package names are currently supported"
    end
  end

  def build_aliased_name(package, version), do: "#{package}@#{version}"

  defp adaptor_exists?(list, {package_name, version}) do
    IO.inspect([list, {package_name, version}], label: "adaptor_exists?/2")

    Enum.find(list, fn %{name: n, version: v} ->
      n == package_name && (v == version || is_nil(version))
    end)
  end
end
