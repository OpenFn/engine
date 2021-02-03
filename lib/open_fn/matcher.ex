defmodule OpenFn.Matcher do
  @moduledoc """
  Documentation for `OpenFn.Matcher`.
  """

  def get_matches(triggers, %{body: body}) do
    Enum.filter(triggers, fn trigger ->
      trigger
      |> OpenFn.CriteriaTrigger.to_expectations()
      |> Enum.all?(&is_match?(&1, body))
    end)
  end

  @doc """
  Determines if a map of data matches the expectations using JSONPath.

  Expects to be given a string-keyed map, and a list of expectation tuples.

  ```
  data = %{"a" => 1, "b" => %{"c" => 2}}
  expectations = [{"$.a", 1}, {"$.b.c", 2}]
  is_match?(expectation, data) # => true
  ```
  """
  def is_match?({path, expectation}, %{} = data) do
    {:ok, results} = ExJSONPath.eval(data, path)
    Enum.at(results, 0) == expectation
  end
end
