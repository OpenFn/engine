defmodule OpenFn.EngineTest do
  use ExUnit.Case
  doctest OpenFn.Engine

  test "greets the world" do
    assert OpenFn.Engine.hello() == :world
  end
end
