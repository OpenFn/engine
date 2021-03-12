defmodule OpenFn.LogAgent do
  use Agent

  def start_link(_ \\ []) do
    Agent.start_link(fn -> {{[], []}, {"", ""}} end)
  end

  def lines(agent) do
    Agent.get(agent, fn {{_, lines}, {_, _}} -> lines end)
  end

  def process_chunk(agent, {_type, data}) when is_pid(agent) do
    agent
    |> Agent.get_and_update(fn {line_state, chunk_state} ->
      reduce_chunk(data, chunk_state)
      |> case do
        {nil, partial_chunk, pending} ->
          {[], {line_state, {partial_chunk, pending}}}

        {chunk, "", pending_chunks} ->
          {pending, lines} = line_state

          {line, pending} =
            String.split(Enum.join(pending) <> chunk, "\n")
            |> Enum.split(-1)

          {line, {{pending, lines ++ line}, {"", pending_chunks}}}
      end
    end)
  end

  def reduce_chunk(data, {partial, pending}) do
    next = pending <> data

    Enum.reduce_while(
      0..byte_size(next),
      {partial, String.next_grapheme(next)},
      fn _, {chunk, grapheme_result} ->
        case grapheme_result do
          {<<_::utf8>> = next_char, rest} ->
            {:cont, {chunk <> IO.iodata_to_binary(next_char), String.next_grapheme(rest)}}

          {next_char, rest} ->
            {:halt, {nil, chunk, next_char <> rest}}

          nil ->
            {:halt, {chunk, "", ""}}
        end
      end
    )
  end
end
