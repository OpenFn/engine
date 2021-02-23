
defmodule OpenFn.Result do
  defstruct [:exit_code, :log, :final_state_path]

  def new(fields \\ []) do
    struct!(__MODULE__, fields)
  end
end
