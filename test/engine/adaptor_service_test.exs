defmodule Engine.AdaptorService.Test do
  use ExUnit.Case, async: true

  alias Engine.AdaptorService

  defmodule Repo do
    def list_local(path) do
      [
        %{name: "@openfn/core", version: "1.3.12"},
        %{name: "@openfn/language-common", version: "1.2.6"}
      ]
    end

    def install(name, dir) do
      :ok
    end
  end

  setup do
    service = start_supervised!({AdaptorService, [
        adaptors_path: "./priv/openfn/runtime",
        repo: Engine.AdaptorService.Test.Repo
    ]})

    %{service: service}
  end

  test "can tell if something is installed or not", %{service: service} do
    assert AdaptorService.installed?(service, "@openfn/core", "1.3.12")
    refute AdaptorService.installed?(service, "@openfn/core", "1.4.0")
  end

  test "can install an adaptor from npm", %{service: service} do
    :ok = AdaptorService.install(service, "@openfn/language-common", "1.2.7")
  end

  test "build_aliased_name" do
    assert "@openfn/language-common-v1.2.6@npm:@openfn/language-common@1.2.6" =
             AdaptorService.build_aliased_name("@openfn/language-common@1.2.6")
  end
end
