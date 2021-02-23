defmodule OpenFn.RunBroadcaster.UnitTest do
  use ExUnit.Case, async: true
  alias OpenFn.{RunRepo, RunBroadcaster, Config, CriteriaTrigger, CronTrigger, Job}

  setup do
    config =
      Config.new(
        triggers: [
          CriteriaTrigger.new(name: "test", criteria: %{"a" => 1}),
          cron_trigger = CronTrigger.new(name: "cron-trigger", cron: "* * * * *")
        ],
        jobs: [
          %Job{name: "test-job", trigger: "test"},
          cron_job = %Job{name: "cron-job", trigger: "cron-trigger"}
        ]
      )

    run_repo_name = :run_broadcaster_run_repo_test

    start_supervised!(
      {RunBroadcaster,
       %RunBroadcaster.StartOpts{
         name: :test_run_broadcaster,
         run_dispatcher: :test_run_dispatcher,
         config: config,
         run_repo: run_repo_name
       }}
    )

    start_supervised!(
      {RunRepo,
       %RunRepo.StartOpts{
         name: run_repo_name
       }}
    )

    start_supervised!({TestServer, [name: :test_run_dispatcher, owner: self()]})

    %{
      broadcaster: :test_run_broadcaster,
      cron_trigger: cron_trigger,
      run_repo: run_repo_name,
      cron_job: cron_job
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
    run_repo: run_repo,
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

    RunRepo.add_run(
      run_repo,
      OpenFn.Run.new(
        job: cron_job,
        result: OpenFn.Result.new(final_state_path: "file path"),
        finished: -1
      )
    )

    RunBroadcaster.handle_trigger(
      :test_run_broadcaster,
      cron_trigger
    )

    got_a_run =
      receive do
        {:invoke_run,
         %OpenFn.Run{
           trigger: ^cron_trigger,
           initial_state: {:file, "file path"}
         }} -> true

        any ->
          IO.puts("Got: #{inspect(any)}")
          false
      after
        100 -> false
      end

    assert got_a_run
  end
end
