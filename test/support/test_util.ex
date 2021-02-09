defmodule Engine.TestUtil do
  def fixture(name, type \\ :json) do
    path = "test/fixtures/#{Atom.to_string(name)}.#{type}"
    File.read!(path)
  end

  import ExUnit.Assertions

  def has_ok_results(results) do
    assert length(results) > 0

    assert Enum.all?(results, fn result ->
             case result do
               {:ok, %OpenFn.Result{}} -> true
               _ -> false
             end
           end)
  end
end
