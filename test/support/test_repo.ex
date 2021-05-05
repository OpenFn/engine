defmodule TestRepo do
  @behaviour Engine.Adaptor.Repo

  def list_local(_path) do
    [
      %Engine.Adaptor{name: "@openfn/core", version: "1.3.12", status: :present},
      %Engine.Adaptor{name: "@openfn/language-common", version: "1.2.6", status: :present}
    ]
  end

  def install(name, dir) do
    GenServer.call(__MODULE__, {:install, [name, dir]})
    :ok
  end
end
