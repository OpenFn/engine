defmodule Engine.LogAgent.UnitTest do
  use ExUnit.Case, async: true

  alias Engine.LogAgent

  test "reduce_chunk/2 handles cases when String.next_grapheme returns {_any, List}" do
    strange = <<225, 158, 128, 225, 158, 185, 225>>
    assert String.next_grapheme(strange) == {"កឹ", [<<225>>]}

    partial = ""

    next =
      <<114, 101, 102, 101, 114, 114, 97, 108, 95, 102, 114, 111, 109, 95, 111, 115, 99, 97, 114,
        34, 44, 10, 32, 32, 32, 32, 32, 32, 32, 32, 34, 111, 115, 99, 97, 114, 95, 99, 97, 115,
        101, 95, 119, 111, 114, 107, 101, 114, 95, 110, 97, 109, 101, 34, 58, 32, 34, 225, 158,
        128, 225, 158, 185, 225>>

    chunk_state = {"", ""}

    data =
      <<114, 101, 102, 101, 114, 114, 97, 108, 95, 102, 114, 111, 109, 95, 111, 115, 99, 97, 114,
        34, 44, 10, 32, 32, 32, 32, 32, 32, 32, 32, 34, 111, 115, 99, 97, 114, 95, 99, 97, 115,
        101, 95, 119, 111, 114, 107, 101, 114, 95, 110, 97, 109, 101, 34, 58, 32, 34, 225, 158,
        128, 225, 158, 185, 225>>

    assert Engine.LogAgent.LogState.reduce_chunk(data, chunk_state) ==
             {"referral_from_oscar\",\n        \"oscar_case_worker_name\": \"កឹ", {"", ""}}
  end

  test "process_chunk/2 with strange data" do
    {:ok, agent} = LogAgent.start_link()

    strange =
      <<114, 101, 102, 101, 114, 114, 97, 108, 95, 102, 114, 111, 109, 95, 111, 115, 99, 97, 114,
        34, 44, 10, 32, 32, 32, 32, 32, 32, 32, 32, 34, 111, 115, 99, 97, 114, 95, 99, 97, 115,
        101, 95, 119, 111, 114, 107, 101, 114, 95, 110, 97, 109, 101, 34, 58, 32, 34, 225, 158,
        128, 225, 158, 185, 225>>

    assert LogAgent.process_chunk(agent, {:stdout, strange}) ==
             "referral_from_oscar\",\n        \"oscar_case_worker_name\": \"កឹ"
  end

  test "process_chunk/2" do
    {:ok, agent} = LogAgent.start_link()

    example = ~s[
      "national_id_no": "39-7008-858-6",
      "name_last": "มมซึฆเ",
      "name_first": "ศผ่องรี",
      "date_of_birth": "1969-02-16",
      "age": 52,
    ]

    example
    |> chunk_string(64)
    |> Enum.each(fn chunk ->
      LogAgent.process_chunk(agent, {:stdout, chunk})
    end)

    buffer = LogAgent.buffer(agent)
    assert length(buffer) == 2
    assert buffer |> Enum.join() == example

    Agent.stop(agent)

    {:ok, agent} = LogAgent.start_link()

    emoji_string = String.duplicate(".", 63) <> "💣"

    first_chunk = LogAgent.process_chunk(agent, {:stdout, binary_part(emoji_string, 0, 64)})
    second_chunk = LogAgent.process_chunk(agent, {:stdout, binary_part(emoji_string, 64, 3)})

    assert first_chunk == nil
    assert second_chunk == emoji_string

    Agent.stop(agent)
  end

  defp chunk_string(str, chunksize) do
    :binary.bin_to_list(str)
    |> Enum.chunk_every(chunksize)
    |> Enum.map(&:binary.list_to_bin/1)
  end
end
