defmodule OpenFn.Credential do
  defstruct [
    :name,
    :body
  ]

  def new(fields \\ []) do
    struct!(__MODULE__, fields)
  end
end
