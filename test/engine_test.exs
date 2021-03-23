defmodule Engine.UnitTest do
  use ExUnit.Case, async: true
  doctest Engine

  alias Engine.{Message, Job, Result, Config}

  @tag skip: true
  test "execute_sync/2" do
    body = Jason.decode!(~s({"a": 1}))

    expression = """
      alterState(state => {
        return state
      })
    """

    {:ok, %Result{} = result} =
      Engine.execute_sync(%Message{body: body}, %Job{
        expression: expression,
        adaptor: "@openfn/language-common"
      })

    assert result.exit_code == 0
    assert File.read!(result.final_state_path) == "{\n  \"a\": 1\n}"
  end

  @tag skip: true
  test "handle_message/2" do
    body = Jason.decode!(~s({"a": 1}))

    config_yaml = ~S"""
    jobs:
      job-1:
        expression: none
        adaptor: @openfn/language-common
        trigger: trigger-2
      job-2:
        expression: none
        adaptor: @openfn/language-common
        trigger: trigger-3
      job-3:
        expression: none
        adaptor: @openfn/language-common
        trigger: trigger-3

    triggers:
      trigger-2:
        criteria: '{"a":1}'
      trigger-3:
        criteria: '{"b":2}'
    """

    {:ok, config} = Config.parse(config_yaml)
    [run] = Engine.handle_message(config, %Message{body: body})

    assert File.read!(run.result.final_state_path) == "{\n  \"a\": 1\n}"
  end

  @tag skip: true
  test "handle_trigger/2" do
    body = Jason.decode!(~s({"a": 1}))

    config_yaml = ~S"""
    jobs:
      job-3:
        expression: none
        adaptor: @openfn/language-common
        trigger: trigger-2

    triggers:
      trigger-2:
        cron: '* * * * *'
    """

    {:ok, config} = Config.parse(config_yaml)
    trigger = hd(Config.triggers(config, :cron))
    [{:ok, result}] = Engine.handle_trigger(config, trigger)

    assert File.read!(result.final_state_path) == "{}"
  end

  test "get_job_state/2" do
    config_yaml = ~S"""
    jobs:
      job-3:
        expression: none
        adaptor: @openfn/language-common
        trigger: trigger-2
    """

    Temp.track!()

    job_state_repo = :engine_test_job_state_repo

    start_supervised!({
      Engine.JobStateRepo,
      %Engine.JobStateRepo.StartOpts{name: job_state_repo, basedir: Temp.path!()}
    })

    # {:ok, config} = Config.parse(config_yaml)

    assert Engine.get_job_state(job_state_repo, %Job{name: "job-3"}) == nil

    state_path = Temp.path!()
    File.write!(state_path, ~s({"foo": "bar"}))
    new_state = Engine.JobStateRepo.register(job_state_repo, %Job{name: "job-3"}, state_path)

    assert Engine.get_job_state(job_state_repo, %Job{name: "job-3"}) == %{"foo" => "bar"}
  end
end
