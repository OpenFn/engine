defmodule Engine.Matcher.UnitTest do
  use ExUnit.Case
  doctest Engine.Matcher

  alias Engine.{Matcher, CriteriaTrigger}

  setup do
    %{message: %{body: %{"a" => 1}}}
  end

  test "get_matches/2", %{message: message} do
    triggers = [
      trigger = %CriteriaTrigger{name: "trigger-2", criteria: %{"formId" => "pula_household"}}
    ]

    body = %{"a" => 1, "formId" => "pula_household"}

    assert Matcher.get_matches(triggers, %{body: body}) == [trigger]
  end

  test "is_match?/2", %{message: %{body: body}} do
    assert Matcher.is_match?({"$.a", 1}, body)
  end

  test "configuration" do
    config = ~S"""
      {
        "jobs": {
          "job-1-id": {
            "credential": "cred-1",
            "expression": "https://github.com/openfn/sample/jobs/job1.js",
            "trigger": "trigger-2"
          }
        },
        "triggers": {
          "trigger-2": {
            "criteria": "{a:1}"
          },
          "trigger-wendy": {
            "label": "every minute",
            "cron": "* * * * *"
          }
        }
      }
    """
  end
end
