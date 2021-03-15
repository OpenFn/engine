defmodule OpenFn.RunSpec do
  @moduledoc """
  A struct containing all the parameters required to execute a Job.
  """
  @type t :: %__MODULE__{
          expression_path: String.t(),
          adaptors_path: String.t(),
          adaptor: String.t(),
          state_path: String.t(),
          final_state_path: String.t(),
          test_mode: boolean(),
          no_console: boolean()
        }

  @enforce_keys [:adaptor]
  defstruct @enforce_keys ++
              [
                :expression_path,
                :adaptors_path,
                :state_path,
                :final_state_path,
                :test_mode,
                :no_console
              ]
end
