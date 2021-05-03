defmodule Engine.AdaptorRepo do
  def list_local(path) do
    Path.wildcard("#{path}/*/*/*/package.json")
    |> Enum.map(fn package_json ->
      res = Jason.decode!(File.read!(package_json))
      get = &Map.get(res, &1)

      %{
        name: get.("name"),
        version: get.("version")
      }
    end)
  end

  @doc """
  |------------ alias ---------| |----- source &|| version -------|
  @openfn/language-common-v1.2.6@npm:@openfn/language-common@1.2.6
  """
  def install(adaptor, dir) when is_binary(adaptor),
    do: install([adaptor], dir)

  def install(adaptors, dir) when is_list(adaptors) do
    adaptors = Enum.join(adaptors, " ")

    System.cmd(
      "/usr/bin/env",
      [
        "sh",
        "-c",
        "npm install --no-save --no-package-lock --global-style #{adaptors} --prefix #{dir}"
      ],
      stderr_to_stdout: true,
      into: IO.stream(:stdio, :line)
    )

    :ok
  end
end

defmodule Engine.AdaptorService do
  use GenServer

  def start_link(opts) do
    GenServer.start_link(
      __MODULE__,
      %{repo: opts[:repo] || Engine.AdaptorRepo, adaptors_path: opts[:adaptors_path]},
      name: __MODULE__
    )
  end

  def init(args) do
    {:ok, args}
  end

  def handle_call(
        {:installed?, package_name, version},
        _from,
        state = %{repo: repo, adaptors_path: adaptors_path}
      ) do
    found =
      repo.list_local(adaptors_path)
      |> Enum.find(fn %{name: n, version: v} ->
        n == package_name && v == version
      end)

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

  def installed?(server, package_name, version) do
    server |> GenServer.call({:installed?, package_name, version})
  end

  def install(server, package_name, version) do
    server |> GenServer.call({:install, package_name, version})
  end

  def build_aliased_name(package, version) do
    "#{package}@#{version}"
  end

  def build_aliased_name(package) do
    package
    |> String.split("@")
    |> case do
      [_, name, version] ->
        "@#{name}-v#{version}@npm:@#{name}@#{version}"

      [_, _name] ->
        package

      _ ->
        raise ArgumentError, "Only npm style package names are currently supported"
    end
  end
end
