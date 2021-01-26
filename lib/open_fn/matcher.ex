defmodule OpenFn.Matcher do
  @moduledoc """
  Documentation for `OpenFn.Matcher`.
  """

  use GenServer

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts)
  end

  def init(init_arg) do
    {:ok, init_arg}
  end

  def list_jobs() do

  end

  @doc """
  Hello world.

  ## Examples

      iex> OpenFn.Engine.hello()
      :world

  """
  def hello do
    :world
  end

  def get_matches(jobs, message) do
    []

  end
end
