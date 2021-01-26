defmodule OpenFn.Engine do
  @moduledoc """
  Documentation for `OpenFn.Engine`.
  """

  @spec child_spec(keyword) :: Supervisor.child_spec()
  defdelegate child_spec(options), to: OpenFn.Engine.Supervisor

  @doc """
  Hello world.

  ## Examples

      iex> OpenFn.Engine.hello()
      :world

  """
  def hello do
    :world
  end

  # TODO: define %Message{}, and %Job{} types
  # TODO: can we deal with module name conflicts?
  def execute_sync(%{} = message, %{} = job) do
    {:ok, state_path} = Temp.path(%{prefix: "state", suffix: ".json"})
    {:ok, final_state_path} = Temp.path(%{prefix: "final_state", suffix: ".json"})
    {:ok, expression_path} = Temp.path(%{prefix: "expression", suffix: ".js"})

    OpenFn.ShellRuntime.run(%{
      state_path: state_path,
      final_state_path: final_state_path,
      expression_path: expression_path
    })
  end

  # TODO: execute_sync with "\\ dispatcher" to forward execute to a worker
end
