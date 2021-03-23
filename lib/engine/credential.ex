defmodule Engine.Credential do
  defstruct [
    :name,
    :body
  ]

  def new(fields \\ []) do
    struct!(__MODULE__, fields)
  end
end
