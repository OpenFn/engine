defmodule Engine.AdaptorAgent do
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
  def install_adaptor(adaptor, dir) when is_binary(adaptor),
    do: install_adaptor([adaptor], dir)

  def install_adaptor(adaptors, dir) when is_list(adaptors) do
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


  def build_aliased_name(package) do
    package
    |> String.split("@")
    |> case do
      [_, name, version] ->

        "@#{name}-v#{version}@npm:@#{name}@#{version}"
      [_, _name] -> package
      _ -> raise ArgumentError, "Only npm style package names are currently supported"
    end
  end
end
