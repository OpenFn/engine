defmodule Engine.Adaptor.Repo do
  @callback list_local(path :: String.t()) :: list(Engine.Adaptor.t())
  def list_local(path, _depth \\ 4) when is_binary(path) do
    System.cmd("npm", ~w[list --global --json --long --prefix #{path}])
    |> case do
      {stdout, 0} ->
        stdout
        |> String.trim()
        |> Jason.decode!()
        |> Map.get("dependencies", %{})
        |> Enum.map(fn {local_name, details} ->
          %Engine.Adaptor{
            name: details["name"],
            version: details["version"],
            path: details["path"],
            local_name: local_name,
            status: :present
          }
        end)

      {_, 254} ->
        raise "No such directory: #{inspect(path)}"

      {stdout, _} ->
        raise "Failed to list adaptors from path: #{path}\n#{stdout}"
    end
  end

  @doc """
  ```
  |------------ alias ---------| |----- source &|| version -------|
  @openfn/language-common-v1.2.6@npm:@openfn/language-common@1.2.6
  ```
  """
  @callback install(adaptors :: list(String.t()) | String.t(), dir :: String.t()) ::
              {Collectable.t(), exit_status :: non_neg_integer}
  @spec install(adaptors :: list(String.t()) | String.t(), dir :: String.t()) ::
          {Collectable.t(), exit_status :: non_neg_integer}
  def install(adaptor, dir) when is_binary(adaptor),
    do: install([adaptor], dir)

  def install(adaptors, dir) when is_list(adaptors) do
    System.cmd(
      "/usr/bin/env",
      [
        "sh",
        "-c",
        """
        npm install \
          --no-save \
          --ignore-scripts \
          --no-fund \
          --no-audit \
          --no-package-lock \
          --global \
          --prefix #{dir} \
          #{Enum.join(adaptors, " ")}
        """
      ],
      stderr_to_stdout: true
    )
  end

  @doc """
  Given a list of _potentially_ nested package.json files (i.e. dependancies of
  our adaptors), `filter_parent_paths/1` reduces the list down to the parent
  directories by grouping directory names by their shortest common path.
  """
  def filter_parent_paths(paths) when is_list(paths) do
    paths
    |> Enum.sort(:desc)
    |> Enum.reduce([], fn path, acc ->
      base = path |> String.replace("package.json", "")

      parent =
        acc
        |> Enum.find(base, fn parent -> String.contains?(base, parent) end)

      acc ++ [parent]
    end)
    |> Enum.uniq()
    |> Enum.map(fn folder -> "#{folder}package.json" end)
  end
end
