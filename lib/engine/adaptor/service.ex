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

  Using the `install/2` function an adaptor can be installed, which will also
  add it to the list of available adaptors.

  The adaptor is marked as `:installing`, to allow for conditional behaviour
  elsewhere such as delaying or rejecting processing until the adaptor becomes
  available.

  ## Looking up adaptors

  The module leans on Elixir's built-in `Version` module to provide version
  lookups.

  When looking up an adaptor, either a string or a tuple can be used.
  In the case of requesting the latest version, any one of these will return
  the latest version the service is aware of.

  - `@openfn/language-http`
  - `@openfn/language-http@latest`
  - `{"@openfn/language-http", nil}`
  - `{"@openfn/language-http", "latest"}`
  - `{~r/language-http/, "latest"}`

  You can also request a specific version, or use a range specification:

  - `@openfn/language-http@1.2.3`
  - `{"@openfn/language-http", "~> 1.2.0"}`
  - `{"@openfn/language-http", "< 2.0.0"}`

  > **NOTE**
  > More complex npm style install strings like: `">=0.1.0 <0.2.0"`
  > are not supported.
  > Generally the tuple style is preferred when using range specifications as
  > the npm style strings have a simplistic regex splitter.

  See [Version](https://hexdocs.pm/elixir/Version.html) for more details on
  matching versions.
  """

  @type package_spec :: {name :: String.t() | Regex.t(), version :: String.t() | nil}

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

    def refresh_list(state) do
      %{state | adaptors: state.repo.list_local(state.adaptors_path)}
    end

    def add_adaptor(state, adaptor) do
      %{state | adaptors: state.adaptors ++ [adaptor]}
    end

    def remove_adaptor(state, fun) do
      %{state | adaptors: Enum.reject(state.adaptors, fun)}
    end
  end

  def start_link(opts) do
    state = struct!(State, opts) |> State.refresh_list()

    Agent.start_link(fn -> state end, name: state.name || __MODULE__)
  end

  def get_adaptors(agent) do
    Agent.get(agent, fn state -> state.adaptors end)
  end

  @spec find_adaptor(Agent.agent(), package :: String.t()) :: Adaptor.t() | nil
  def find_adaptor(agent, package) when is_binary(package) do
    find_adaptor(agent, resolve_package_name(package))
  end

  @spec find_adaptor(Agent.agent(), package_spec()) :: Adaptor.t() | nil
  def find_adaptor(agent, {package_name, version}) do
    requirement = version_to_requirement(version)

    get_adaptors(agent)
    |> Enum.filter(&by_name_and_requirement(&1, package_name, requirement))
    |> Enum.max_by(
      fn %{version: version} ->
        Version.parse!(version)
      end,
      Version,
      fn -> nil end
    )
  end

  defp by_name_and_requirement(adaptor, matcher = %Regex{}, requirement) do
    !!(Regex.match?(matcher, adaptor.name) &&
         Version.match?(adaptor.version, requirement))
  end

  defp by_name_and_requirement(adaptor, name, requirement) do
    !!(match?(%{name: ^name}, adaptor) &&
         Version.match?(adaptor.version, requirement))
  end

  defp version_to_requirement(version) do
    cond do
      version in ["latest", nil] ->
        "> 0.0.0"

      String.match?(version, ~r/[<=>]/) ->
        raise ArgumentError, message: "Version specs not implemented yet."

      true ->
        version
    end
    |> Version.parse_requirement!()
  end

  def installed?(agent, package_spec) do
    !!find_adaptor(agent, package_spec)
  end

  @spec install(Agent.agent(), binary()) ::
          {:ok, Engine.Adaptor.t()} | {:error, {Collectable.t(), exit_status :: non_neg_integer}}
  def install(agent, package) when is_binary(package) do
    install(agent, resolve_package_name(package))
  end

  @spec install(Agent.agent(), package_spec()) ::
          {:ok, Engine.Adaptor.t()} | {:error, {Collectable.t(), exit_status :: non_neg_integer}}
  def install(agent, package_spec) do
    agent
    |> find_adaptor(package_spec)
    |> case do
      nil -> install!(agent, package_spec)
      existing -> {:ok, existing}
    end
  end

  @spec install!(Agent.agent(), package_spec()) ::
          {:ok, Engine.Adaptor.t()} | {:error, {Collectable.t(), exit_status :: non_neg_integer}}
  def install!(agent, {package_name, version} = package_spec) do
    new_adaptor = %Engine.Adaptor{name: package_name, version: version, status: :installing}

    agent |> Agent.update(&State.add_adaptor(&1, new_adaptor))

    {repo, adaptors_path} =
      agent
      |> Agent.get(fn state ->
        {state.repo, state.adaptors_path}
      end)

    repo.install(build_aliased_name(package_spec), adaptors_path)
    |> case do
      {_stdout, 0} ->
        Logger.info("Refreshing Adaptor list")
        adaptors = repo.list_local(adaptors_path)
        agent |> Agent.update(fn state -> %{state | adaptors: adaptors} end)
        {:ok, find_adaptor(agent, {package_name, version})}

      {stdout, code} ->
        agent
        |> Agent.update(fn state ->
          State.remove_adaptor(state, &match?(^new_adaptor, &1))
        end)

        {:error, {stdout, code}}
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
       `@openfn/language-http-1.2.8@npm:@openfn/language-http@1.2.8`

  Which is pretty long winded but necessary for the reason above.

  If using this module as a base, it's likely you would need to adaptor this
  to suit your particular naming strategy.
  """
  def build_aliased_name({package, version}) do
    "#{package}-#{version}@npm:#{package}@#{version}"
  end
end
