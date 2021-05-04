defmodule Engine.Adaptor.Repo do
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
