defmodule TestServer do
  use GenServer

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts[:owner], name: opts[:name])
  end

  def init(owner) do
    {:ok, owner}
  end

  def handle_call(msg, _from, owner) do
    send(owner, msg)
    {:reply, msg, owner}
  end
end
