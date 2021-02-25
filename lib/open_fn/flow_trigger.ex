defmodule OpenFn.FlowTrigger do
  defstruct name: nil, success: ""

  def new(fields \\ []) do
    struct!(__MODULE__, fields)
  end

end
