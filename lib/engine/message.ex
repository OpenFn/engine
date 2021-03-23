defmodule Engine.Message do
  @moduledoc """
  Struct for holding information about an incoming message.

  A Message is a bag of data containing the body of the payload.
  """
  defstruct body: nil
end
