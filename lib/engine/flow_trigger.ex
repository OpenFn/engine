defmodule Engine.FlowTrigger do
  @type t :: %__MODULE__{
          name: String.t(),
          success: String.t() | nil,
          failure: String.t() | nil
        }

  @enforce_keys [:name]
  defstruct @enforce_keys ++ [success: nil, failure: nil]

  def new(fields \\ []) do
    struct!(__MODULE__, fields)
  end
end
