defmodule OpenFn.CriteriaTrigger.UnitTest do
  use ExUnit.Case, async: true

  alias OpenFn.CriteriaTrigger

  test "to_expectations/1" do
    assert CriteriaTrigger.to_expectations(%CriteriaTrigger{
             criteria: %{"formId" => "pula_household"}
           }) == [{"$.formId", "pula_household"}]

  end
end
