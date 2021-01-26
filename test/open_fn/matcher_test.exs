defmodule OpenFn.MatcherTest do
  use ExUnit.Case
  doctest OpenFn.Matcher

  alias OpenFn.Matcher

  test "greets the world" do
    assert Matcher.hello() == :world
  end

  setup do
    %{message: %{a: 1}}
  end

  # test "matching", %{message: message} do
  #   assert Matcher.get_matches(jobs, message) == []
  # end

  # test "configuration" do
  #   config = ~S"""
  #     {
  #       "jobs": {
  #         "job-1-id": {
  #           "credential": "cred-1",
  #           "expression": "https://github.com/openfn/sample/jobs/job1.js",
  #           "trigger": "trigger-2"
  #         }
  #       },
  #       "triggers": {
  #         "trigger-2": {
  #           "criteria": "{a:1}"
  #         },
  #         "trigger-wendy": {
  #           "label": "every minute",
  #           "cron": "* * * * *"
  #         }
  #       }
  #     }
  #   """

  #   {:ok, pid} = Matcher.start_link(config)

  #   send(pid, )

  #   assert Matcher.list_jobs(pid) == []
  # end
end
