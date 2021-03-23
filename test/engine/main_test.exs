defmodule Main do
  def match(jobs, message) do
    []
  end
end

defmodule MainTest do
  use ExUnit.Case, async: true

  setup do
    %{jobs: []}
  end

  test "main", %{jobs: jobs} do
    matches = Main.match(jobs, %{body: ~S({"a": 1})})

    assert matches == []
  end
end
