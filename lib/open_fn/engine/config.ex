defmodule Engine.Config do
  @moduledoc """
  Configuration for an Engine process, parse/1 expects either a schema-based
  path or a string.
  """
  defstruct jobs: [], triggers: []
  @type t :: %__MODULE__{jobs: any(), triggers: any()}

  def parse("file://" <> path) do
    YamlElixir.read_from_file(path)
    |> case do
      {:ok, data} ->
        {:ok, __MODULE__.from_map(data)}
      any -> any
    end
  end

  def parse(str) do
    {:ok, data} = YamlElixir.read_from_string(str)

    {:ok, data |> __MODULE__.from_map}
  end

  @doc """
  Cast a serialisable map of config into a Config struct.
  """
  @spec from_map(map) :: Engine.Config.t()
  def from_map(data) do
    %__MODULE__{
      jobs: Map.get(data, "jobs", %{}),
      triggers: Map.get(data, "triggers", %{})
    }
  end
end
