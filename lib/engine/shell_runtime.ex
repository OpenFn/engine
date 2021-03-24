defmodule Engine.ShellRuntime do
  alias Engine.{RunSpec, Result}
  require Logger

  def run(%RunSpec{} = runspec, opts \\ []) do
    command = build_command(runspec)
    IO.inspect(runspec, pretty: true, label: "runspec")
    env = build_env(runspec, opts[:env])

    rambo_opts =
      Keyword.merge(
        [timeout: nil, log: false],
        opts |> Keyword.take([:timeout, :log])
      )
      |> Keyword.put(:env, env)

    Logger.debug("""
    env: #{Enum.map(rambo_opts[:env], fn {k, v} -> "#{k}=#{v}" end) |> Enum.join(" ")}
    cmd: #{command}
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
           log: !!rambo_opts[:log] || res.err <> res.out,
           final_state_path: runspec.final_state_path
         }}

      {:error, _} ->
        raise "Command failed to execute."
    end
  end

  def build_command(%RunSpec{} = runspec) do
    ~s"""
      core execute \
      -e #{runspec.expression_path} \
      -l #{runspec.adaptor} \
      -s #{runspec.state_path} \
      #{(runspec.final_state_path && "-o #{runspec.final_state_path} ") || ""}
      #{(runspec.test_mode && "--test ") || ""}
      #{(runspec.no_console && "--noConsole") || ""}
    """
  end

  def build_env(%RunSpec{memory_limit: memory_limit}, env) when not is_nil(memory_limit) do
    %{"NODE_OPTIONS" => "--max-old-space-size=#{memory_limit}"}
    |> Map.merge(env || %{})
  end

  def build_env(_runspec, env), do: env
end
