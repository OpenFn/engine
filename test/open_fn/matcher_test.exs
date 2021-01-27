defmodule OpenFn.MatcherTest do
  use ExUnit.Case
  doctest OpenFn.Matcher

  alias OpenFn.Matcher

  setup do
    %{message: %{body: %{"a" => 1}}}
  end

  setup do
    %{message: %{a: 1}}
  end

  # test "matching", %{message: message} do
  #   assert Matcher.get_matches(jobs, message) == []
  # end

    assert Matcher.get_matches(triggers, message) == trigger
  end

  test "is_match?/2", %{message: %{body: body}} do
    assert Matcher.is_match?(body, [{"$.a", 1}])
  end

  #   {:ok, pid} = Matcher.start_link(config)

  #   send(pid, )

  #   assert Matcher.list_jobs(pid) == []
  # end
end
