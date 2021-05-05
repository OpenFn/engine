defmodule Engine.Adaptor.Service.Test do
  use ExUnit.Case, async: true

  alias Engine.Adaptor.Service

  setup do
    start_supervised!({TestServer, [name: TestRepo, owner: self()]})

    service =
      start_supervised!(
        {Service,
         [
           adaptors_path: adaptors_path = "./priv/openfn/runtime",
           repo: TestRepo
         ]}
      )

    %{service: service, adaptors_path: adaptors_path}
  end

  test "checks for existing adaptors immediately", %{service: service} do
    assert length(Service.get_adaptors(service)) > 0
  end

  test "can tell if something is installed or not", %{service: service} do
    assert Service.installed?(service, "@openfn/core", "1.3.12")
    assert Service.installed?(service, "@openfn/core", nil)

    refute Service.installed?(service, "@openfn/core", "1.4.0")
  end

  test "can install an adaptor from npm", %{service: service, adaptors_path: adaptors_path} do
    installed_adaptor = %Engine.Adaptor{
      name: "@openfn/language-common",
      version: "1.2.7",
      status: :present
    }

    assert installed_adaptor == Service.install(service, "@openfn/language-common", "1.2.7")

    assert_received {:install, ["@openfn/language-common@1.2.7", ^adaptors_path]}, 100

    assert Service.get_adaptors(service)
           |> Enum.find(&match?(^installed_adaptor, &1))
  end

  test "build_aliased_name" do
    assert "@openfn/language-common-v1.2.6@npm:@openfn/language-common@1.2.6" ==
             Service.build_aliased_name("@openfn/language-common@1.2.6")

    assert "@openfn/language-common-latest@npm:@openfn/language-common" ==
             Service.build_aliased_name("@openfn/language-common@latest")

    assert "@openfn/language-common" ==
             Service.build_aliased_name("@openfn/language-common")
  end
end
