defmodule Engine.ConfigTest do
  use ExUnit.Case, async: true

  test "can parse a config file" do
    {:error, %YamlElixir.FileNotFoundError{}} = Engine.Config.parse("file://config_file.yaml")
  end

  test "can parse a string" do
    example = ~S"""
    jobs:
      job-1:
        expression: none
        trigger: trigger-2

    triggers:
      trigger-2:
        criteria: '{a:1}'
    """

    {:ok, %Engine.Config{jobs: jobs, triggers: triggers}} = Engine.Config.parse(example)

    assert Map.keys(jobs) == ["job-1"]
    assert Map.keys(triggers) == ["trigger-2"]
  end
end
