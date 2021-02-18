defmodule OpenFn.Result do
  defstruct [:exit_code, :log, :final_state_path]
end

defmodule OpenFn.ShellRuntime do
  alias OpenFn.{RunSpec, Result}
  require Logger

  def run(%RunSpec{} = runspec, rambo_opts \\ []) do
    command = build_command(runspec)

    env = %{
      "NODE_PATH" => "priv/openfn/runtime/node_modules"
      # "NODE_ENV" => Application.get_env(:open_fn, :node_js_env),
      # "PATH" => "..."
    }

    Logger.debug("""
    env: #{Enum.map(env, fn {k, v} -> "#{k}=#{v}" end)}
    cmd: #{command}
    """)

    # TODO: improve error handling and feedback when modules can't be found
    # TODO: stream stderr & stdout into Collectable - add that to %Result{}
    Rambo.run(
      "/usr/bin/env",
      ["sh", "-c", command],
      Keyword.merge(
        [
          env: env,
          timeout: nil,
          log: false
        ],
        rambo_opts
      )
    )
    |> case do
      {msg, %Rambo{} = res} ->
        {msg,
         %Result{
           exit_code: res.status,
           log: rambo_opts[:log] || (res.err <> res.out),
           final_state_path: runspec.final_state_path
         }}

      {:error, _} ->
        raise "Command failed to execute."
    end
  end

  def build_command(%RunSpec{} = runspec) do
    test_mode = nil
    no_console = nil

    # TODO: build this string up using a list of lists and joining with \
    #       i.e. [[flag, value], [flag]] |> String.join(" \\\n")
    ~s"""
      (cd $NODE_PATH && ./.bin/core execute \
      -e #{runspec.expression_path} \
      -l #{runspec.language_pack} \
      -s #{runspec.state_path} \
      #{(runspec.final_state_path && "-o #{runspec.final_state_path} ") || ""}
      #{(test_mode && "--test ") || ""}
      #{(no_console && "--noConsole") || ""}
      )
    """
  end
end
