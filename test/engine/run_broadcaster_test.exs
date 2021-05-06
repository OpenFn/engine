defmodule Engine.RunBroadcaster.UnitTest do
  use ExUnit.Case, async: true

  alias Engine.{
    JobStateRepo,
    RunBroadcaster,
    Config,
    CriteriaTrigger,
    CronTrigger,
    FlowTrigger,
    Job,
    Credential,
    Run
  }

  setup do
    Temp.track!()

    config =
      Config.new(
        credentials: [
          test_credential =
            Credential.new(name: "test-credential", body: %{username: "un", password: "pw"})
        ],
        jobs: [
          test_job = Job.new(name: "test-job", trigger: "test", credential: "test-credential", adaptor: "@openfn/language-http"),
          cron_job = Job.new(name: "cron-job", trigger: "cron-trigger", adaptor: "@openfn/language-http"),
          success_flow_job = Job.new(name: "flow-job", trigger: "after-test-job", adaptor: "@openfn/language-http"),
          failure_flow_job = Job.new(name: "flow-job-failure", trigger: "after-test-job-failure", adaptor: "@openfn/language-http")
        ],
        triggers: [
          CriteriaTrigger.new(name: "test", criteria: %{"a" => 1}),
          cron_trigger = CronTrigger.new(name: "cron-trigger", cron: "* * * * *"),
          success_flow_trigger = FlowTrigger.new(name: "after-test-job", success: "test-job"),
          failure_flow_trigger =
            FlowTrigger.new(name: "after-test-job-failure", failure: "test-job")
        ]
      )

    job_state_repo_name = :run_broadcaster_job_state_repo_test

    start_supervised!({TestServer, [name: :test_run_dispatcher, owner: self()]})
    start_supervised!({TestServer, [name: TestRepo, owner: self()]}, id: :test_repo)

    start_supervised!(
      {Engine.Adaptor.Service,
        [
          adaptors_path: adaptors_path = "./priv/openfn/runtime",
          repo: TestRepo,
          name: :test_adaptor_service
        ]}
    )

    start_supervised!(
      {RunBroadcaster,
       %RunBroadcaster.StartOpts{
         name: :test_run_broadcaster,
         run_dispatcher: :test_run_dispatcher,
         adaptor_service: :test_adaptor_service,
         config: config,
         job_state_repo: job_state_repo_name
       }}
    )

    start_supervised!(
      {JobStateRepo,
       %JobStateRepo.StartOpts{
         name: job_state_repo_name,
         basedir: Temp.path!()
       }}
    )

    %{
      broadcaster: :test_run_broadcaster,
      cron_trigger: cron_trigger,
      success_flow_trigger: success_flow_trigger,
      failure_flow_trigger: failure_flow_trigger,
      job_state_repo: job_state_repo_name,
      cron_job: cron_job,
      success_flow_job: success_flow_job,
      failure_flow_job: failure_flow_job,
      test_job: test_job,
      test_credential: test_credential
    }
  end

  test "matches up a CriteriaTrigger to a message" do
    RunBroadcaster.handle_message(
      :test_run_broadcaster,
      %{body: %{"a" => 1}}
    )

    assert_received {:invoke_run, %Engine.Run{}}, 100
  end

  test "matches up a CronTrigger to a message", %{
    cron_trigger: cron_trigger,
    job_state_repo: job_state_repo,
    cron_job: cron_job
  } do
    RunBroadcaster.handle_trigger(
      :test_run_broadcaster,
      cron_trigger
    )

    got_a_run =
      receive do
        {:invoke_run, %Engine.Run{trigger: ^cron_trigger}} ->
          true

        any ->
          IO.puts("Got: #{inspect(any)}")
          false
      after
        100 -> false
      end

    assert got_a_run

    state_path = Temp.path!(suffix: "run-broadcaster-test.json")
    File.write!(state_path, ~s({"foo": 1}))

    JobStateRepo.register(
      job_state_repo,
      cron_job,
      state_path
    )

    RunBroadcaster.handle_trigger(
      :test_run_broadcaster,
      cron_trigger
    )

    # Should receive a call to :invoke_run with the previous runs state
    assert_receive {:invoke_run,
                    %Engine.Run{
                      trigger: ^cron_trigger,
                      initial_state: %{"foo" => 1}
                    }}
  end

  test "matches up a FlowTrigger to a Run", %{
    success_flow_job: success_flow_job,
    failure_flow_job: failure_flow_job,
    success_flow_trigger: success_flow_trigger,
    failure_flow_trigger: failure_flow_trigger,
    job_state_repo: job_state_repo,
    test_job: test_job
  } do
    state_path = Temp.path!(suffix: "run-broadcaster-test.json")
    File.write!(state_path, ~s({"foo": "bar"}))

    JobStateRepo.register(
      job_state_repo,
      test_job,
      state_path
    )

    # test-job succeeded
    RunBroadcaster.process(
      :test_run_broadcaster,
      %Run{job: test_job, result: %Engine.Result{exit_code: 0}}
    )

    assert_receive {
      :invoke_run,
      %Run{
        trigger: ^success_flow_trigger,
        job: ^success_flow_job,
        initial_state: %{"foo" => "bar"}
      }
    }

    refute_received {
      :invoke_run,
      %Run{trigger: ^failure_flow_trigger}
    }

    RunBroadcaster.process(
      :test_run_broadcaster,
      %Run{job: test_job, result: %Engine.Result{exit_code: 1}}
    )

    assert_receive {
      :invoke_run,
      %Run{
        trigger: ^failure_flow_trigger,
        job: ^failure_flow_job,
        initial_state: %{"foo" => "bar"}
      }
    }

    refute_received {
      :invoke_run,
      %Run{trigger: ^success_flow_trigger}
    }
  end
end
