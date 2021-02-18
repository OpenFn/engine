defmodule OpenFn.Engine do
  @moduledoc """
  Documentation for `OpenFn.Engine`.
  """

  @spec child_spec(keyword) :: Supervisor.child_spec()
  defdelegate child_spec(options), to: OpenFn.Engine.Supervisor

  use Application

  @doc false
  def start(_type, _args) do
    children = []

    opts = [strategy: :one_for_one]
    Supervisor.start_link(children, opts)
  end

  alias OpenFn.{Message, Job, RunSpec, Config}

  def execute_sync(%Message{} = message, %Job{} = job) do
    {:ok, state_path} = Temp.path(%{prefix: "state", suffix: ".json"})
    {:ok, final_state_path} = Temp.path(%{prefix: "final_state", suffix: ".json"})
    {:ok, expression_path} = Temp.path(%{prefix: "expression", suffix: ".js"})

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
    # TODO: take in 'EngineConfig' instead of Config
    OpenFn.RunBroadcaster.handle_message(:run_broadcaster, message)
  end

  def handle_trigger(%Config{} = config, trigger) do
    Config.jobs_for(config, [trigger])
    |> Enum.map(&execute_sync(%Message{body: %{}}, &1))
  end

  def config(engine, key) when is_atom(key) do
    :"#{engine}_registry"
    |> Registry.meta(key)
    |> case do
      {:ok, config} -> config
      any -> any
    end
  end
end
