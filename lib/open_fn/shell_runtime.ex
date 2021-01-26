defmodule OpenFn.ShellRuntime do
  def run(%{}) do
    arguments = build_command(%{})

    Rambo.run("/bin/sh", ["-c", Enum.join(arguments, " ")],
      # env: env,
      timeout: nil,
      log: &stderr_to_stdout/1
    )
  end

  defp stderr_to_stdout({_kind, line}), do: line

  def build_command(%{}) do
    expression_path = "1"
    language_packs_path = "1"
    language_pack = "1"
    state_path = "1"
    final_state_path = nil
    test_mode = nil
    no_console = nil

    ~w(
      core execute
      -e #{expression_path}
      -l #{language_packs_path}/#{language_pack}.Adaptor
      -s #{state_path}
      #{final_state_path && ["-o", final_state_path] || nil}
      #{test_mode && "--test" || nil}
      #{no_console && "--noConsole" || nil}
    )
  end
end
