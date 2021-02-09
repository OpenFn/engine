defmodule OpenFn.Engine do
  @moduledoc """
  Documentation for `OpenFn.Engine`.
  """

  @spec child_spec(keyword) :: Supervisor.child_spec()
  defdelegate child_spec(options), to: OpenFn.Engine.Supervisor

  alias OpenFn.{Message, Job, RunSpec, Config, Matcher}
  def execute_sync(%Message{} = message, %Job{} = job) do
    {:ok, state_path} = Temp.path(%{prefix: "state", suffix: ".json"})
    {:ok, final_state_path} = Temp.path(%{prefix: "final_state", suffix: ".json"})
    {:ok, expression_path} = Temp.path(%{prefix: "expression", suffix: ".js"})

    # Assemble state
    # TODO: find a home for setting up the state given the job type/trigger
    # TODO: ensure sane default and helpful errors _before_ trying to execute
    File.write!(state_path, Jason.encode!(message.body))
    File.write!(expression_path, job.expression || "")

    OpenFn.ShellRuntime.run(%RunSpec{
      state_path: state_path,
      final_state_path: final_state_path,
      expression_path: expression_path,
      language_pack: job.language_pack
    })
  end

  def handle_message(%Config{} = config, %Message{} = message) do
    triggers = Matcher.get_matches(config.triggers, message)

    Config.jobs_for(config, triggers)
    |> Enum.map(&execute_sync(message, &1))
  end

  def config(engine, key) when is_atom(key) do
    Module.concat(engine, "Registry")
    |> Registry.meta(key)
    |> case do
      {:ok, config} -> config
      any -> any
    end
  end
end
