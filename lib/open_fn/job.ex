defmodule OpenFn.Job do
  defstruct [
    :name,
    :expression,
    :configuration,
    :language_pack,
    :trigger
  ]
end
