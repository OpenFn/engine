defmodule Engine.Job do
  defstruct [
    :name,
    :expression,
    :credential,
    :adaptor,
    :trigger
  ]

  def new(fields \\ []) do
    struct!(__MODULE__, fields)
  end
end
