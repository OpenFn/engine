defmodule OpenFn.LogStream do
  @moduledoc """
  Creates a Stream with an accompanying callback function to add log lines
  as the process is running.

  Included in the processing, is a reducer that deals with incomplete
  UTF-8 bitstrings. For example when a 64 byte message comes in and the last
  byte is the first of a 4-byte character; `IO.iodata_to_binary/1` raises
  an exception.

  The stream will only emit values when they are valid UTF-8 binaries.

  _NOTE_: The processing is eager, it doesn't wait until a new-line character
  before emitting a value. This can be handled further down-stream if needed.
  """

  def create(parent \\ self()) do
    line_stream = Stream.resource(fn -> {"", ""} end, &loop/1, fn _ -> nil end)

    callback = fn msg -> send(parent, msg) end

    {line_stream, callback}
  end

  defp loop({partial_chunk, pending}) do
    receive do
      {_type, data} ->
        process_chunk(data, {partial_chunk, pending})
        |> case do
          {nil, partial_chunk, pending} ->
            {[], {partial_chunk, pending}}

          {chunk, "", pending} ->
            {[chunk], {"", pending}}
        end

      :complete ->
        {:halt, pending}
    end
  end

  defp process_chunk(data, {partial, pending}) do
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
