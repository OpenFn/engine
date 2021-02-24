defmodule OpenFn.JobStateRepo do
  @moduledoc """
  Responsible for storing runs
  """
  use GenServer
  require Logger

  alias OpenFn.{Job}

  defmodule StartOpts do
    @moduledoc false

    @type t :: %__MODULE__{
            name: GenServer.name(),
            basedir: String.t()
          }

    @enforce_keys [:name, :basedir]
    defstruct @enforce_keys
  end

  defmodule State do
    @moduledoc false

    @type t :: %__MODULE__{
            basedir: String.t()
          }

    @enforce_keys [:basedir]
    defstruct @enforce_keys
  end

  def start_link(%StartOpts{} = opts) do
    state =
      opts
      |> Map.take([:basedir])

    GenServer.start_link(__MODULE__, state, name: opts.name)
  end

  def init(opts) do
    {:ok, struct!(State, opts)}
  end

  def handle_call({:register, job, state_path}, _from, state) do
    :ok =
      try_copy(
        state_path,
        job_file_path(state.basedir, job, "last-persisted-state.json")
      )

    Logger.debug("Adding run to repo.")
    {:reply, :ok, state}
  end

  def handle_call({:get_last_persisted_state_path, job}, _from, state) do
    {:reply, job_file_path(state.basedir, job, "last-persisted-state.json"), state}
  end

  defp try_copy(src, dest) do
    case File.cp(src, dest) do
      {:error, :enoent} ->
        File.mkdir_p!(Path.dirname(dest))
        File.cp!(src, dest)

      {:error, reason} ->
        raise File.CopyError,
          reason: reason,
          action: "copy",
          source: IO.chardata_to_string(src),
          destination: IO.chardata_to_string(dest)

      :ok ->
        :ok
    end
  end

  defp job_file_path(basedir, %Job{name: name}, filename) do
    Path.join([basedir, name, filename])
  end


  def register(server, %Job{} = job, state_path),
    do: GenServer.call(server, {:register, job, state_path})

  def get_last_persisted_state_path(server, job = %Job{}),
    do: GenServer.call(server, {:get_last_persisted_state_path, job})
end
