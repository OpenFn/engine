defmodule Engine.TestUtil do
  def fixture(name, type \\ :json) do
    path = "test/fixtures/#{Atom.to_string(name)}.#{type}"
    File.read!(path)
  end
end
