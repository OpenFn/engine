defmodule Engine.LogAgent.UnitTest do
  use ExUnit.Case, async: true

  alias Engine.LogAgent

  test "process_chunk/2" do
    {:ok, agent} = LogAgent.start_link()

    assert LogAgent.process_chunk(agent, {:stdout, "logmessage"}) == []
    assert LogAgent.process_chunk(agent, {:stdout, "log\nmessage"}) == ["logmessagelog"]

    assert LogAgent.pending(agent) == ["message"]

    assert LogAgent.process_chunk(agent, {:stdout, "another\n"}) == ["messageanother"]
    assert LogAgent.lines(agent) == ["logmessagelog", "messageanother"]
  end
end
