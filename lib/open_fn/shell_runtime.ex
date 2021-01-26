defmodule OpenFn.ShellRuntime do
  def run(_job) do
    arguments = ~w(ls -al)

    Rambo.run("/bin/sh", ["-c", Enum.join(arguments, " ")],
      # env: env,
      timeout: nil,
      log: &stderr_to_stdout/1
    )
  end

  defp stderr_to_stdout({_kind, line}), do: line
end
