defmodule OpenFn.ConfigTest do
  use ExUnit.Case, async: true

  alias OpenFn.{Config, CriteriaTrigger, CronTrigger, Job}

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
        trigger-4:
          cron: "* * * * *"
      """
    }
  end

  @tag :config
  test "can parse a config file" do
    {:error, %YamlElixir.FileNotFoundError{}} = Config.parse("file://config_file.yaml")
  end

  @tag :config
  test "can parse a string", %{example_string: example} do
    {:ok, %Config{jobs: jobs, triggers: triggers}} = Config.parse(example)

    assert [%Job{name: "job-1"}, %Job{name: "job-2"}, %Job{name: "job-3"}] = jobs

    assert [
             %CriteriaTrigger{name: "trigger-2"},
             %CriteriaTrigger{name: "trigger-3"},
             %CronTrigger{name: "trigger-4", cron: "* * * * *"}
           ] = triggers
  end

  @tag :config
  test "jobs_for/1", %{example_string: example} do
    {:ok, config} = Config.parse(example)

    assert [%Job{name: "job-1"}] = Config.jobs_for(config, [%CriteriaTrigger{name: "trigger-2"}])

    assert [%Job{name: "job-2"}, %Job{name: "job-3"}] =
             Config.jobs_for(config, [%CriteriaTrigger{name: "trigger-3"}])

    assert [] = Config.jobs_for(config, [%CriteriaTrigger{name: "trigger-nope"}])
  end

  @tag :config
  test "triggers/1", %{example_string: example} do
    {:ok, config} = Config.parse(example)

    assert [%{name: "trigger-4"}] = Config.triggers(config, :cron)
    assert [%{name: "trigger-2"},  %{name: "trigger-3"}] = Config.triggers(config, :criteria)

    # assert [%Job{name: "job-2"}, %Job{name: "job-3"}] =
    #          Config.jobs_for(config, [%CriteriaTrigger{name: "trigger-3"}])

    # assert [] = Config.jobs_for(config, [%CriteriaTrigger{name: "trigger-nope"}])
  end
end
