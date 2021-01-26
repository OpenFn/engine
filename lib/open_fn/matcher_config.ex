defmodule OpenFn.MatcherConfig do
  use Agent

  @doc """
  Starts a new matcher config.
  """
  def start_link(_opts) do
    Agent.start_link(fn -> %{} end)
  end

  @doc """
  Gets a value from the `bucket` by `key`.
  """
  def get(config, key) do
    Agent.get(config, &Map.get(&1, key))
  end

  @doc """
  Puts the `value` for the given `key` in the `config`.
  """
  def put(config, key, value) do
    Agent.update(config, &Map.put(&1, key, value))
  end
end
