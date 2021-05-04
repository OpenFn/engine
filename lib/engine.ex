defmodule Engine do
  @moduledoc """
  Documentation for `Engine`.
  """

  @spec child_spec(keyword) :: Supervisor.child_spec()
  defdelegate child_spec(options), to: Engine.Supervisor

  use Application

  @doc false
  def start(_type, _args) do
    children = []

    opts = [strategy: :one_for_one]
    Supervisor.start_link(children, opts)
  end

  alias Engine.{Message, Job}

  @doc """
  DEPRECATED
  """
  def execute_sync(%Message{}, %Job{}) do
    raise "execute_sync/2 is no longer supported"
  end

  def handle_message(run_broadcaster, %Message{} = message) do
    Engine.RunBroadcaster.handle_message(run_broadcaster, message)
  end

  def handle_trigger(run_broadcaster, trigger) do
    Engine.RunBroadcaster.handle_trigger(run_broadcaster, trigger)
  end

  def get_job_state(job_state_repo, %Job{} = job) do
    path = Engine.JobStateRepo.get_last_persisted_state_path(job_state_repo, job)

    case File.stat(path) do
      {:ok, _stat} -> Jason.decode!(File.read!(path))
      {:error, _reason} -> nil
    end
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
