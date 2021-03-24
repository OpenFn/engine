defmodule Engine.LogAgent do
  @type logline :: {timestamp :: integer(), type :: :stdout | :stderr, line :: binary()}

  defmodule LogState do
    @typep line_state :: {[binary()], [binary()]}
    @typep chunk_state :: {bitstring(), bitstring()}

    @type t :: {
            line_state :: line_state(),
            chunk_state :: chunk_state()
          }

    @spec new() :: t()
    def new() do
      {{[], []}, {"", ""}}
    end

    @spec lines(state :: LogState.t()) :: [binary()]
    def lines({{_, lines}, _}), do: lines

    @spec pending(state :: LogState.t()) :: [binary()]
    def pending({{pending, _}, _}), do: pending

    @spec process_chunk(data :: any(), state :: LogState.t()) :: {[binary()], LogState.t()}
    def process_chunk(data, {line_state, chunk_state}) do
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
    end

    @spec reduce_chunk(data :: any(), chunk_state :: chunk_state()) ::
            {binary() | nil, binary(), binary()}
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

  use Agent

  def start_link(_ \\ []) do
    Agent.start_link(&LogState.new/0)
  end

  def lines(agent) do
    Agent.get(agent, &LogState.lines/1)
  end

  def pending(agent) do
    Agent.get(agent, &LogState.pending/1)
  end

  def process_chunk(agent, {_type, data}) when is_pid(agent) do
    agent |> Agent.get_and_update(&LogState.process_chunk(data, &1))
  end
end
