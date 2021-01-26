defmodule OpenFn.Engine.UnitTest do
  use ExUnit.Case, async: true
  doctest OpenFn.Engine

  describe "child_spec/1" do
    test "expects a name" do
      {:error, {{:EXIT, {exception, _}}, _}} = start_supervised({OpenFn.Engine, []})

      assert Exception.message(exception) ==
               "the :name option is required when starting OpenFn.Engine"
    end
  end

  test "greets the world" do
    assert OpenFn.Engine.hello() == :world
  end

  test "execute_sync/2" do
    OpenFn.Engine.execute_sync(%{}, %{})

  end
end
