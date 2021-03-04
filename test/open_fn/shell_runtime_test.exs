defmodule OpenFn.ShellRuntimeTest do
  use ExUnit.Case, async: true

  alias OpenFn.RunSpec

  @tag skip: true
  test "works" do
    {:ok, %Rambo{}} = OpenFn.ShellRuntime.run(%RunSpec{})
  end

  test "when used with LogStream" do
    {line_stream, stream_callback} = OpenFn.LogStream.create()

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
end
