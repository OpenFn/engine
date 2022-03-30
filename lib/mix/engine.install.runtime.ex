defmodule Mix.Tasks.Openfn.Install.Runtime do
  @shortdoc "Install the essential NodeJS packages for running expressions/jobs"

  @moduledoc """
  Installs the following NodeJS packages:

  - core
  - language-common
  """

  use Mix.Task

  @default_path "priv/openfn"

  def run(_) do
    Rambo.run("/usr/bin/env", ~w(which node))
    |> case do
      {:error, %{status: 1}} ->
        raise "Couldn't find node in the local environment."

      _ ->
        nil
    end

    File.mkdir_p(@default_path)
    |> case do
      {:error, reason} ->
        raise "Couldn't create the runtime directory: #{@default_path}, got :#{reason}."

      _ ->
        nil
    end

    package_list = packages() |> Enum.join(" ")

    System.cmd(
      "/usr/bin/env",
      [
        "sh",
        "-c",
        "npm install --prefix $NODE_PATH --global #{package_list}"
      ],
      env: [{"NODE_PATH", @default_path}],
      stderr_to_stdout: true,
      into: IO.stream(:stdio, :line)
    )
  end

  def packages() do
    ~W(
      @openfn/core@latest
      @openfn/language-common@latest
    )
  end
end
