defmodule OpenFn.Config do
  @moduledoc """
  Configuration for an Engine process, parse/1 expects either a schema-based
  path or a string.
  """
  defstruct jobs: [], triggers: []
  @type t :: %__MODULE__{jobs: any(), triggers: any()}

  alias OpenFn.{CriteriaTrigger, Job}

  def parse("file://" <> path) do
    YamlElixir.read_from_file(path)
    |> case do
      {:ok, data} ->
        {:ok, __MODULE__.from_map(data)}

      any ->
        any
    end
  end

  def parse(str) do
    {:ok, data} = YamlElixir.read_from_string(str)

    {:ok, data |> __MODULE__.from_map()}
  end

  @doc """
  Cast a serialisable map of config into a Config struct.
  """
  @spec from_map(map) :: Engine.Config.t()
  def from_map(data) do
    trigger_data = Map.get(data, "triggers", %{})
    job_data = Map.get(data, "jobs", %{})

    triggers =
      for {name, trigger_opts} <- trigger_data, into: [] do
        %CriteriaTrigger{name: name, criteria: Map.get(trigger_opts, "criteria")}
      end

    jobs =
      for {name, job_opts} <- job_data, into: [] do
        %Job{name: name, trigger: Map.get(job_opts, "trigger")}
      end

    %__MODULE__{
      jobs: jobs,
      triggers: triggers
    }
  end

  def jobs_for(%__MODULE__{} = config, triggers) do
    Enum.filter(config.jobs, fn j ->
      Enum.any?(triggers, fn t ->
        t.name == j.trigger
      end)
    end)
  end
end
