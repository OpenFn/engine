# OpenFn.Engine [![CircleCI](https://circleci.com/gh/OpenFn/engine.svg?style=svg)](https://circleci.com/gh/OpenFn/engine)

A processing framework for executing jobs using the OpenFn ecosystem of 
language packs.

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `openfn_engine` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:openfn_engine, "~> 0.1.0"}
  ]
end
```

## Mix Tasks

- `openfn.install.runtime`  
  Assuming NodeJS is installed, it will install the latest versions of the most
  basic language packs.

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/openfn_engine](https://hexdocs.pm/openfn_engine).

