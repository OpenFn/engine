defmodule Engine.Adaptor do
  @moduledoc false
  @type install_status :: :present | :installing

  @type t :: %__MODULE__{
          name: binary(),
          version: binary(),
          path: binary(),
          status: install_status(),
          local_name: binary()
        }

  @enforce_keys [:name, :version]
  defstruct @enforce_keys ++ [:status, :path, :local_name]

  def set_present(adaptor) do
    %{adaptor | status: :present}
  end
end
