defmodule OpenFn.ShellRuntimeTest do
  use ExUnit.Case, async: true

  alias OpenFn.RunSpec

  @tag skip: true
  test "works" do
    {:ok, %Rambo{}} = OpenFn.ShellRuntime.run(%RunSpec{})
  end

  test "can deal with bitstrings" do
    {:ok, agent} = Agent.start_link(fn -> {[], "", ""} end)

    f = fn {_type, data} ->
      Agent.update(agent, fn {lines, current_chunk, pending} ->
        next_chunk = pending <> data

        {state, chunk, pending} =
          Enum.reduce_while(
            0..byte_size(next_chunk),
            {current_chunk, String.next_grapheme(next_chunk)},
            fn _, {chunk, grapheme_result} ->
              case grapheme_result do
                {<<_::utf8>> = next_char, rest} ->
                  {:cont, {chunk <> IO.iodata_to_binary(next_char), String.next_grapheme(rest)}}

                {next_char, rest} ->
                  {:halt, {:incomplete, chunk, next_char <> rest}}

                nil ->
                  {:halt, {:done, chunk, ""}}
              end
            end
          )

        case state do
          :incomplete ->
            {lines, chunk, pending}

          :done ->
            {lines ++ [chunk], nil, pending}
        end
      end)
    end

    Rambo.run("echo", [String.duplicate(".", 63) <> "💣"], log: f)

    assert Agent.get(agent, fn value -> value end) ==
             {["...............................................................💣\n"], nil, ""}
  end
end
