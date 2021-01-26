defmodule OpenFn.ShellRuntimeTest do
  use ExUnit.Case, async: true

  test "works" do
    {:ok, %Rambo{}} = OpenFn.ShellRuntime.run(%{})
  end
end
