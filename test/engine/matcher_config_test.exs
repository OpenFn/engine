defmodule Engine.MatcherConfigTest do
  use ExUnit.Case, async: true
  alias Engine.MatcherConfig
  doctest Engine.MatcherConfig

  setup do
    {:ok, config} = MatcherConfig.start_link([])
    %{config: config}
  end

  test "stores values by key", %{config: config} do
    assert MatcherConfig.get(config, "jobs") == nil

    MatcherConfig.put(config, "jobs", 3)
    assert MatcherConfig.get(config, "jobs") == 3
  end
end
