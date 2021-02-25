defmodule OpenFn.RunBroadcaster.UnitTest do
  use ExUnit.Case, async: true

  alias OpenFn.{
    JobStateRepo,
    RunBroadcaster,
    Config,
    CriteriaTrigger,
    CronTrigger,
    FlowTrigger,
    Job,
    Run
  }

  setup do
    Temp.track!()

    config =
      Config.new(
        triggers: [
          CriteriaTrigger.new(name: "test", criteria: %{"a" => 1}),
          cron_trigger = CronTrigger.new(name: "cron-trigger", cron: "* * * * *"),
          flow_trigger = FlowTrigger.new(name: "after-test-job", success: "test-job")
        ],
        jobs: [
          test_job = Job.new(name: "test-job", trigger: "test"),
          cron_job = Job.new(name: "cron-job", trigger: "cron-trigger"),
          flow_job = Job.new(name: "flow-job", trigger: "after-test-job")
        ]
      )

    job_state_repo_name = :run_broadcaster_job_state_repo_test

    start_supervised!({TestServer, [name: :test_run_dispatcher, owner: self()]})

    start_supervised!(
      {RunBroadcaster,
       %RunBroadcaster.StartOpts{
         name: :test_run_broadcaster,
         run_dispatcher: :test_run_dispatcher,
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
      flow_trigger: flow_trigger,
      job_state_repo: job_state_repo_name,
      cron_job: cron_job,
      flow_job: flow_job,
      test_job: test_job
    }
  end

  test "matches up a CriteriaTrigger to a message" do
    RunBroadcaster.handle_message(
      :test_run_broadcaster,
      %{body: %{"a" => 1}}
    )

    got_a_run =
      receive do
        {:invoke_run, %OpenFn.Run{}} ->
          true

        _ ->
          false
      after
        100 -> false
      end

    assert got_a_run
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
        {:invoke_run, %OpenFn.Run{trigger: ^cron_trigger}} ->
          true

        any ->
          IO.puts("Got: #{inspect(any)}")
          false
      after
        100 -> false
      end

    assert got_a_run

    state_path = Temp.path!(suffix: "run-broadcaster-test.json")
    File.touch!(state_path)

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
    got_a_run =
      receive do
        {:invoke_run,
         %OpenFn.Run{
           trigger: ^cron_trigger,
           initial_state: {:file, path}
         }} ->
          assert String.contains?(path, "/cron-job/last-persisted-state.json")
          true

        any ->
          IO.puts("Got: #{inspect(any)}")
          false
      after
        100 -> false
      end

    assert got_a_run
  end

  test "matches up a FlowTrigger to a Run", %{
    flow_job: flow_job,
    flow_trigger: flow_trigger,
    job_state_repo: job_state_repo,
    test_job: test_job
  } do
    state_path = Temp.path!(suffix: "run-broadcaster-test.json")
    File.touch!(state_path)

    JobStateRepo.register(
      job_state_repo,
      flow_job,
      state_path
    )

    RunBroadcaster.process(
      :test_run_broadcaster,
      %Run{job: test_job, result: %OpenFn.Result{exit_code: 0}}
    )

    got_a_run =
      receive do
        {:invoke_run, %Run{} = run} ->
          assert run.job == flow_job
          assert run.trigger == flow_trigger

          {:file, path} = run.initial_state
          assert String.contains?(path, "/flow-job/last-persisted-state.json")

          true
        any ->
          IO.puts("Got: #{inspect(any, pretty: true)}")
          false
      after
        100 -> false
      end

    assert got_a_run

    RunBroadcaster.process(
      :test_run_broadcaster,
      %Run{job: test_job, result: %OpenFn.Result{exit_code: 1}}
    )

    # Will not invoke a flow if the Run failed.
    refute_receive {:invoke_run, _}
  end
end
