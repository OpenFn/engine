defmodule OpenFn.Matcher do
  @moduledoc """
  Documentation for `OpenFn.Matcher`.
  """

  use GenServer

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts)
  end

  def init(init_arg) do
    {:ok, init_arg}
  end

  def list_jobs() do

  end

  @doc """
  Determines if a map of data matches the expectations using JSONPath.

  Expects to be given a string-keyed map, and a list of expectation tuples.

  ```
  data = %{"a" => 1, "b" => %{"c" => 2}}
  expectations = [{"$.a", 1}, {"$.b.c", 2}]
  is_match?(data, expectations) # => true
  ```
  """
  def is_match?(%{} = data, expectations) do
    expectations
    |> Enum.map(fn {path, value} ->
      {:ok, results} = ExJSONPath.eval(data, path)
      Enum.at(results, 0) == value
    end)
    |> Enum.all?()
  end

  # TODO: convert our criteria style triggers into list of expectations that
  #       work with is_match?/2
  # {
  #   "Envelope": {
  #     "Body": {
  #       "notifications": {
  #         "Notification": [],   <=== Must match that is a list, not an empty list
  #         "OrganizationId": "00DA0000000CmO4MAK"
  #       }
  #     }
  #   }
  # }
end
