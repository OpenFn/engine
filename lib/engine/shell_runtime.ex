defmodule Engine.ShellRuntime do
  alias Engine.{RunSpec, Result}
  require Logger

  def run(%RunSpec{} = runspec, opts \\ []) do
    command = build_command(runspec)
    Logger.debug("ShellRuntime.run/2 called with #{inspect(runspec)}")
    env = build_env(runspec, opts[:env])

    rambo_opts =
      Keyword.merge(
        [timeout: nil, log: false],
        opts |> Keyword.take([:timeout, :log])
      )
      |> Keyword.put(:env, env)

    Logger.debug("""
    env:
    #{Enum.map(rambo_opts[:env], fn {k, v} -> "#{k}=#{v}" end) |> Enum.join(" ")}
    cmd:
    #{command}
    """)

    Rambo.run(
      "/usr/bin/env",
      ["sh", "-c", command],
      rambo_opts
    )
    |> case do
      {msg, %Rambo{} = res} ->
        {msg,
         %Result{
           exit_reason: msg,
           exit_code: res.status,
           log: String.split(res.err <> res.out, "\n"),
           final_state_path: runspec.final_state_path
         }}

      {:error, _} ->
        raise "Command failed to execute."
    end
  end

  @doc """
  Builds up a string for shell execution based on the RunSpec
  """
  @spec build_command(runspec :: %RunSpec{}) :: binary()
  def build_command(%RunSpec{} = runspec) do
    flags =
      [
        {"-e", runspec.expression_path},
        {"-l", runspec.adaptor},
        {"-s", runspec.state_path},
        if(runspec.final_state_path, do: {"-o", runspec.final_state_path}),
        if(runspec.test_mode, do: {"--test", nil}),
        if(runspec.no_console, do: {"--noConsole", nil})
      ]
      |> Enum.map(&to_shell_args/1)
      |> Enum.reject(&is_nil/1)
      |> Enum.join(" \\\n  ")

    ~s"""
    core execute \\
      #{flags}
    """
  end

  defp to_shell_args(nil), do: nil
  defp to_shell_args({key, nil}), do: key
  defp to_shell_args({key, value}), do: "#{key} #{value}"

  def build_env(%RunSpec{memory_limit: memory_limit}, env) when not is_nil(memory_limit) do
    %{"NODE_OPTIONS" => "--max-old-space-size=#{memory_limit}"}
    |> Map.merge(env || %{})
  end

  def build_env(_runspec, env), do: env
end
