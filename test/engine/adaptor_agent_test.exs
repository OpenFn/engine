defmodule Engine.AdaptorAgent.Test do
  use ExUnit.Case, async: true

  alias Engine.AdaptorAgent

  test "can get list of locally available adaptors" do
    path = "./priv/openfn/runtime"
    adaptors = AdaptorAgent.list_local(path)

    assert adaptors == [
             %{name: "@openfn/core", version: "1.3.12"},
             %{name: "@openfn/language-common", version: "1.2.6"}
           ]
  end

  @tag skip: true
  test "can install an adaptor from npm" do
    path = "./priv/openfn/runtime"
    :ok = AdaptorAgent.install_adaptor("@openfn/language-common@1.2.7", path)

    adaptors = AdaptorAgent.list_local(path)

    assert adaptors == [
             %{name: "@openfn/core", version: "1.3.12"},
             %{name: "@openfn/language-common", version: "1.2.6"}
           ]
  end

  test "build_aliased_name" do
    assert "@openfn/language-common-v1.2.6@npm:@openfn/language-common@1.2.6" =
             AdaptorAgent.build_aliased_name("@openfn/language-common@1.2.6")
  end
end
