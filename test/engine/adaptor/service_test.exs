defmodule Engine.Adaptor.Service.Test do
  use ExUnit.Case, async: true

  alias Engine.Adaptor
  alias Engine.Adaptor.Service

  setup do
    start_supervised!({TestServer, [name: TestRepo, owner: self()]})

    service =
      start_supervised!(
        {Service,
         [
           adaptors_path: adaptors_path = "./priv/openfn/lib",
           repo: TestRepo
         ]}
      )

    %{service: service, adaptors_path: adaptors_path}
  end

  test "checks for existing adaptors immediately", %{service: service} do
    assert length(Service.get_adaptors(service)) > 0
  end

  test "can tell if something is installed or not", %{service: service} do
    assert Service.installed?(service, {"@openfn/core", "1.3.12"})
    assert Service.installed?(service, {"@openfn/core", nil})
    refute Service.installed?(service, {"@openfn/core", "1.4.0"})
  end

  test "can perform lookups on adaptors", %{service: service} do
    %Adaptor{name: "@openfn/core", version: "1.3.12"} =
      Service.find_adaptor(service, "@openfn/core@1.3.12")

    assert_raise ArgumentError, "Version specs not implemented yet.", fn ->
      %Adaptor{name: "@openfn/core", version: "1.3.12"} =
        Service.find_adaptor(service, {"@openfn/core", ">=1.3.10 <2.0.0"})
    end

    assert_raise ArgumentError, "Version specs not implemented yet.", fn ->
      nil = Service.find_adaptor(service, {"@openfn/core", "< 1.3.12"})
    end

    %Adaptor{name: "@openfn/core", version: "1.3.12"} =
      Service.find_adaptor(service, "@openfn/core@latest")

    %Adaptor{name: "@openfn/language-common", version: "1.2.8"} =
      Service.find_adaptor(service, {"@openfn/language-common", "latest"})

    %Adaptor{name: "@openfn/language-common", version: "1.2.6"} =
      Service.find_adaptor(service, {"@openfn/language-common", "1.2.6"})
  end

  test "can install an adaptor from npm", %{service: service, adaptors_path: adaptors_path} do
    Service.install(service, {"@openfn/language-common", "1.2.7"})

    assert_receive {:install,
                    [
                      "@openfn/language-common-1.2.7@npm:@openfn/language-common@1.2.7",
                      ^adaptors_path
                    ]},
                   100

    assert_receive {:list_local, ^adaptors_path}, 100

    result = Service.install!(service, {"@openfn/language-common", "latest"})

    refute result == {:ok, nil}

    assert_receive {:install,
                    [
                      "@openfn/language-common-latest@npm:@openfn/language-common@latest",
                      ^adaptors_path
                    ]},
                   100

    assert_receive {:list_local, ^adaptors_path}, 100
  end

  test "build_aliased_name" do
    assert "@openfn/language-common-1.2.6@npm:@openfn/language-common@1.2.6" ==
             Service.build_aliased_name({"@openfn/language-common", "1.2.6"})
  end
end
