defmodule TestRepo do
  @moduledoc """
  Mock Repo to test calls to Engine.Adaptor.Repo in cases where you don't
  want tests either reading the local file system - or installing adaptors.

  This must be used with `TestServer` in order to validate the arguments
  the module is called with:

  ```
  start_supervised!({TestServer, [name: TestRepo, owner: self()]}, id: :test_repo)
  ```

  The above example starts a TestServer, with a `:name` of `TestRepo`, which in
  turn will send messages back to the test process.
  """
  @behaviour Engine.Adaptor.Repo

  @impl Engine.Adaptor.Repo
  def list_local(path) do
    GenServer.call(__MODULE__, {:list_local, path})

    [
      %Engine.Adaptor{name: "@openfn/core", version: "1.3.12", path: "", status: :present},
      %Engine.Adaptor{
        name: "@openfn/language-common",
        version: "1.2.6",
        path: "",
        status: :present
      },
      %Engine.Adaptor{
        name: "@openfn/language-common",
        version: "1.2.8",
        path: "",
        status: :present
      }
    ]
  end

  @impl Engine.Adaptor.Repo
  def install(name, dir) do
    GenServer.call(__MODULE__, {:install, [name, dir]})
    {:ok, 0}
  end
end
