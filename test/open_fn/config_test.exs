defmodule OpenFn.ConfigTest do
  use ExUnit.Case, async: true

  alias OpenFn.{Config, CriteriaTrigger, Job}

  setup do
    %{
      example_string: ~S"""
      jobs:
        job-1:
          expression: none
          language_pack: language-common
          trigger: trigger-2
        job-2:
          expression: none
          language_pack: language-common
          trigger: trigger-3
        job-3:
          expression: none
          language_pack: language-common
          trigger: trigger-3

      triggers:
        trigger-2:
          criteria: '{"a":1}'
        trigger-3:
          criteria: '{"b":2}'
      """
    }
  end

  test "can parse a config file" do
    {:error, %YamlElixir.FileNotFoundError{}} = Config.parse("file://config_file.yaml")
  end

  test "can parse a string", %{example_string: example} do
    {:ok, %Config{jobs: jobs, triggers: triggers}} = Config.parse(example)

    assert [%Job{name: "job-1"}, %Job{name: "job-2"}, %Job{name: "job-3"}] = jobs
    assert [%CriteriaTrigger{name: "trigger-2"}, %CriteriaTrigger{name: "trigger-3"}] = triggers
  end

  test "jobs_for/1", %{example_string: example} do
    {:ok, config} = Config.parse(example)

    assert [%Job{name: "job-1"}] = Config.jobs_for(config, [%CriteriaTrigger{name: "trigger-2"}])

    assert [%Job{name: "job-2"}, %Job{name: "job-3"}] =
             Config.jobs_for(config, [%CriteriaTrigger{name: "trigger-3"}])

    assert [] = Config.jobs_for(config, [%CriteriaTrigger{name: "trigger-nope"}])
  end
end
