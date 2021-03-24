defmodule Engine.ShellRuntimeTest do
  use ExUnit.Case, async: true
  import Engine.TestUtil

  alias Engine.RunSpec

  @tag skip: true
  test "works" do
    {:ok, %Rambo{}} = Engine.ShellRuntime.run(%RunSpec{adaptors_path: "./", adaptor: ""})
  end

  test "when used with LogStream" do
    {line_stream, stream_callback} = Engine.LogStream.create()

    task =
      Task.async(fn ->
        Rambo.run("echo", [String.duplicate(".", 63) <> "💣"], log: stream_callback)
        Process.sleep(100)
        Rambo.run("echo", [String.duplicate(".", 63) <> "💣\n"], log: stream_callback)
        Rambo.run("echo", [String.duplicate(".", 63) <> "💣"], log: stream_callback)
        stream_callback.(:complete)
      end)

    assert line_stream |> Enum.into([]) == [
             "...............................................................💣\n",
             "...............................................................💣\n\n",
             "...............................................................💣\n"
           ]

    Task.await(task)
  end

  test "allows a memory limit to be set" do
    run_spec = run_spec_fixture(memory_limit: "1")

    assert {:error, result} = Engine.ShellRuntime.run(run_spec, env: %{"PATH" => "#{run_spec.adaptors_path}/.bin:#{System.get_env("PATH")}"})

    assert result.exit_code == 134
    assert result.exit_reason == :error

    assert String.contains?(result.log, "heap out of memory")

  end
end
