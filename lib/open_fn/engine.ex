defmodule OpenFn.Message do
  @moduledoc """
  Struct for holding information about an incoming message.

  A Message is a bag of data containing the body of the payload.
  """
  defstruct body: nil
end

defmodule OpenFn.Engine do
  @moduledoc """
  Documentation for `OpenFn.Engine`.
  """

  @spec child_spec(keyword) :: Supervisor.child_spec()
  defdelegate child_spec(options), to: OpenFn.Engine.Supervisor

  alias OpenFn.{Message, Job, RunSpec, Config, Matcher}

  # TODO: define %Message{}, and %Job{} types
  # TODO: can we deal with module name conflicts?
  def execute_sync(%Message{} = message, %Job{} = job) do
    {:ok, state_path} = Temp.path(%{prefix: "state", suffix: ".json"})
    {:ok, final_state_path} = Temp.path(%{prefix: "final_state", suffix: ".json"})
    {:ok, expression_path} = Temp.path(%{prefix: "expression", suffix: ".js"})

    # Assemble state
    # TODO: find a home for setting up the state given the job type/trigger
    File.write!(state_path, message.body)
    File.write!(expression_path, job.expression)

    OpenFn.ShellRuntime.run(%RunSpec{
      state_path: state_path,
      final_state_path: final_state_path,
      expression_path: expression_path,
      language_pack: job.language_pack
    })
  end

  def handle_message(%Config{} = config, %Message{} = message) do
    triggers = Matcher.get_matches(config.triggers, message)

    Enum.map(triggers, &Config.jobs_for(config, &1))
    |> Enum.map(&execute_sync(message, &1))
  end
end
