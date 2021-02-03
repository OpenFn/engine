defmodule OpenFn.RunSpec do
  @moduledoc """
  A struct containing all the parameters required to execute a Job.
  """

  defstruct [
    :expression_path,
    :language_packs_path,
    :language_pack,
    :state_path,
    :final_state_path,
    :test_mode,
    :no_console
  ]
end
