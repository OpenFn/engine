defmodule Engine.Adaptor.Service do
  @moduledoc """
  The Adaptor Service is use to query and install adaptors in order to run jobs.

  On startup, it queries the filesystem for `package.json` files and builds up
  a list of available adaptors.

  ## Configuration

  The service requires at least `:adaptors_path`, which is used to both query
  which adaptors are installed and when to install new adaptors.

  Another optional setting is: `:repo`, which must point at a module that will be
  used to do the querying and installing.

  ## Installing Adaptors

  Using the `install/3` function an adaptor can be installed, which will also
  add it to the list of available adaptors.

  The adaptor is marked as `:installing`, to allow for conditional behaviour
  elsewhere such as delaying or rejecting processing until the adaptor becomes
  available.
  """

  use Agent
  require Logger

  defmodule State do
    @moduledoc false

    @type t :: %__MODULE__{
            name: GenServer.server(),
            adaptors: [Engine.Adaptor.t()],
            adaptors_path: binary(),
            repo: module()
          }

    @enforce_keys [:adaptors_path]
    defstruct @enforce_keys ++ [:name, adaptors: [], repo: Engine.Adaptor.Repo]

    def find_adaptor(%{adaptors: adaptors}, fun) when is_function(fun) do
      Enum.find(adaptors, fun)
    end

    def find_adaptor(state, {package_name, version}) do
      find_adaptor(state, fn %{name: n, version: v} ->
        n == package_name && (v == version || is_nil(version))
      end)
    end

    def refresh_list(state) do
      %{state | adaptors: state.repo.list_local(state.adaptors_path)}
    end

    def add_adaptor(state, adaptor) do
      %{state | adaptors: state.adaptors ++ [adaptor]}
    end

    def remove_adaptor(state, fun) do
      %{ state | adaptors: Enum.reject(state.adaptors, fun) }
    end
  end

  def start_link(opts) do
    state = struct!(State, opts) |> State.refresh_list()

    Agent.start_link(fn -> state end, name: state.name || __MODULE__)
  end

  def get_adaptors(agent) do
    Agent.get(agent, fn state -> state.adaptors end)
  end

  def find_adaptor(agent, package) do
    {package_name, version} = resolve_package_name(package)
    find_adaptor(agent, package_name, version)
  end

  def find_adaptor(agent, package_name, version) do
    Agent.get(agent, &State.find_adaptor(&1, {package_name, version}))
  end

  def installed?(agent, package_name, version) do
    Agent.get(agent, &State.find_adaptor(&1, {package_name, version}))
  end

  def install(agent, package) do
    Logger.debug("Requesting adaptor: #{package}")
    {package_name, version} = resolve_package_name(package)

    install(agent, package_name, version)
  end

  def install(agent, package_name, version) do
    existing = agent |> __MODULE__.find_adaptor(package_name, version)

    existing || install!(agent, package_name, version)
  end

  def install!(agent, package_name, version) do
    new_adaptor = %Engine.Adaptor{name: package_name, version: version, status: :installing}

    agent |> Agent.update(&State.add_adaptor(&1, new_adaptor))

    {repo, adaptors_path} =
      agent
      |> Agent.get(fn state ->
        {state.repo, state.adaptors_path}
      end)

    repo.install(__MODULE__.build_aliased_name(package_name, version), adaptors_path)
    |> case do
      {:ok, _stdout} ->
        agent |> Agent.update(&State.refresh_list/1)
        # TODO, handle latest version
        agent |> Agent.get(&State.find_adaptor(&1, {package_name, version}))

      {:error, {stdout, _code}} ->
        agent |> Agent.update(fn state ->
          State.remove_adaptor(state, &match?(^new_adaptor, &1))
        end)

        raise "Couldn't install #{package_name} (#{version}).\n#{Enum.join(stdout, "\n")}"
    end
  end

  def resolve_package_name(package_name) when is_binary(package_name) do
    ~r/(@?[\/\d\n\w-]+)(?:@([\d\.\w]+))?$/
    |> Regex.run(package_name)
    |> case do
      [_, name, version] ->
        {name, version}

      [_, _name] ->
        {package_name, nil}

      _ ->
        raise ArgumentError, "Only npm style package names are currently supported"
    end
  end

  @doc """
  Turns a package name and version into a string for NPM.

  Since multiple versions of the same package can be installed, it's important
  to rely on npms built-in package aliasing.

  E.g. `@openfn/language-http@1.2.8` turns into:
       `@openfn/language-common-v1.2.6@npm:@openfn/language-common@1.2.6`

  Which is pretty long winded but necessary for the reason above.

  If using this module as a base, it's likely you would need to adaptor this
  to suit your particular naming strategy.
  """
  @callback build_aliased_name(package :: String.t(), version :: String.t() | nil) :: String.t()
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

  def build_aliased_name(package, version), do: build_aliased_name("#{package}@#{version}")
end
