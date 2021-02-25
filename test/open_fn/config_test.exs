defmodule OpenFn.ConfigTest do
  use ExUnit.Case, async: true

  alias OpenFn.{Config, CriteriaTrigger, CronTrigger, FlowTrigger, Job}

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
        job-4:
          expression: none
          language_pack: language-common
          trigger: after-job-2

      triggers:
        trigger-2:
          criteria: '{"a":1}'
        trigger-3:
          criteria: '{"b":2}'
        trigger-4:
          cron: "* * * * *"
        after-job-2:
          success: "job-2"
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

    assert Enum.map(1..4, fn i ->
             jobs |> Enum.any?(fn j -> j.name == "job-#{i}" end)
           end)
           |> Enum.all?()

    assert [
             %FlowTrigger{name: "after-job-2", success: "job-2"},
             %CriteriaTrigger{name: "trigger-2"},
             %CriteriaTrigger{name: "trigger-3"},
             %CronTrigger{name: "trigger-4", cron: "* * * * *"}
           ] = triggers
  end

  @tag :config
  test "jobs_for/1", %{example_string: example} do
    {:ok, config} = Config.parse(example)

    assert [%Job{name: "job-1"}] =
             config
             |> Config.jobs_for([%CriteriaTrigger{name: "trigger-2"}])

    assert [%Job{name: "job-2"}, %Job{name: "job-3"}] =
             config
             |> Config.jobs_for([%CriteriaTrigger{name: "trigger-3"}])

    assert [%Job{name: "job-4"}] =
             config
             |> Config.jobs_for(
               Config.job_triggers_for(config, %Job{name: "job-2"})
               |> Enum.map(&elem(&1, 1))
             )

    assert [] =
             config
             |> Config.jobs_for([%CriteriaTrigger{name: "trigger-nope"}])
  end

  @tag :config
  test "triggers/2", %{example_string: example} do
    {:ok, config} = Config.parse(example)

    assert [%{name: "trigger-4"}] = Config.triggers(config, :cron)

    assert [
             %{name: "trigger-2"},
             %{name: "trigger-3"}
           ] = Config.triggers(config, :criteria)

    assert [
             %{name: "after-job-2"}
           ] = Config.triggers(config, :flow)
  end

  test "job_triggers_for/2", %{example_string: example} do
    {:ok, config} = Config.parse(example)

    job = %Job{name: "job-2"}
    trigger_job = config.jobs |> Enum.at(3)

    assert [{^trigger_job, %{name: "after-job-2"}}] = Config.job_triggers_for(config, job)
  end
end
