defmodule Engine.Adaptor.Repo.Test do
  use ExUnit.Case, async: true

  alias Engine.Adaptor.Repo

  test "reduce_parent_path/2" do
    listing = [
      "priv/openfn/lib/node_modules/@openfn/core/node_modules/@openfn/doclet-query/package.json",
      "priv/openfn/lib/node_modules/@openfn/core/node_modules/mitm/package.json",
      "priv/openfn/lib/node_modules/@openfn/core/node_modules/recast/node_modules/ast-types/package.json",
      "priv/openfn/lib/node_modules/@openfn/core/node_modules/recast/node_modules/esprima/package.json",
      "priv/openfn/lib/node_modules/@openfn/core/node_modules/recast/package.json",
      "priv/openfn/lib/node_modules/@openfn/core/node_modules/yargs-parser/package.json",
      "priv/openfn/lib/node_modules/@openfn/core/node_modules/yargs/helpers/package.json",
      "priv/openfn/lib/node_modules/@openfn/core/node_modules/yargs/package.json",
      "priv/openfn/lib/node_modules/@openfn/core/package.json",
      "priv/openfn/lib/node_modules/@openfn/language-common/node_modules/axios/package.json",
      "priv/openfn/lib/node_modules/@openfn/language-common/node_modules/lodash/package.json",
      "priv/openfn/lib/node_modules/@openfn/language-common/package.json",
      "priv/openfn/lib/node_modules/node_modules/@openfn/language-common/node_modules/axios/package.json",
      "priv/openfn/lib/node_modules/node_modules/@openfn/language-common/package.json"
    ]

    assert Repo.filter_parent_paths(listing) == [
             "priv/openfn/lib/node_modules/node_modules/@openfn/language-common/package.json",
             "priv/openfn/lib/node_modules/@openfn/language-common/package.json",
             "priv/openfn/lib/node_modules/@openfn/core/package.json"
           ]
  end
end
