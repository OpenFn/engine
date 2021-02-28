defmodule OpenFn.ConfigTest do
  use ExUnit.Case, async: true

  alias OpenFn.{Config, Credential, CriteriaTrigger, CronTrigger, FlowTrigger, Job}

  setup do
    %{
      example_string: ~S"""
      credentials:
        my-secret-credential:
          username: 'user@example.com'
          password: 'shhh'

      jobs:
        job-1:
          expression: none
          language_pack: language-common
          trigger: trigger-2
        job-2:
          credential: my-secret-credential
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
          trigger: after-job-2-success
        job-5:
          expression: none
          language_pack: language-common
          trigger: after-job-2-failure

      triggers:
        trigger-2:
          criteria: '{"a":1}'
        trigger-3:
          criteria: '{"b":2}'
        trigger-4:
          cron: "* * * * *"
        after-job-2-success:
          success: "job-2"
        after-job-2-failure:
          failure: "job-2"
      """
    }
  end

  @tag :config
  test "can parse a config file" do
    {:error, %YamlElixir.FileNotFoundError{}} = Config.parse("file://config_file.yaml")
  end

  @tag :config
  test "can parse a string", %{example_string: example} do
    {:ok, %Config{jobs: jobs, triggers: triggers, credentials: credentials}} =
      Config.parse(example)

    assert Enum.map(1..4, fn i ->
             jobs |> Enum.any?(fn j -> j.name == "job-#{i}" end)
           end)
           |> Enum.all?()

    assert [
             %FlowTrigger{name: "after-job-2-failure", failure: "job-2"},
             %FlowTrigger{name: "after-job-2-success", success: "job-2"},
             %CriteriaTrigger{name: "trigger-2"},
             %CriteriaTrigger{name: "trigger-3"},
             %CronTrigger{name: "trigger-4", cron: "* * * * *"}
           ] = triggers

    assert [
             %Credential{
               name: "my-secret-credential",
               body: %{"password" => "shhh", "username" => "user@example.com"}
             }
           ] = credentials
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

    assert [%Job{name: "job-4"}, %Job{name: "job-5"}] =
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
             %{name: "after-job-2-failure"},
             %{name: "after-job-2-success"}
           ] = Config.triggers(config, :flow)
  end

  test "job_triggers_for/2", %{example_string: example} do
    {:ok, config} = Config.parse(example)

    job = %Job{name: "job-2"}
    trigger_job = config.jobs |> Enum.find(fn j -> j.name == "job-4" end)
    failure_job = config.jobs |> Enum.find(fn j -> j.name == "job-5" end)

    assert [
             {^failure_job, %{name: "after-job-2-failure"}},
             {^trigger_job, %{name: "after-job-2-success"}}
           ] = Config.job_triggers_for(config, job)
  end

  test "credential_body_for/2", %{example_string: example} do
    {:ok, config} = Config.parse(example)

    job = Enum.find(config.jobs, fn x -> x.name == "job-2" end)

    assert %{"password" => "shhh", "username" => "user@example.com"} =
             Config.credential_body_for(config, job)
  end
end
