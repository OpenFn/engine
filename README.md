# Engine [![CircleCI](https://circleci.com/gh/OpenFn/engine.svg?style=svg)](https://circleci.com/gh/OpenFn/engine)

A processing framework for executing jobs using the OpenFn ecosystem of 
language packs.

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `openfn_engine` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:engine, github: "OpenFn/engine", tag: "v0.7.2"}
  ]
end
```

## Using

### As part of your application

With this approach the available jobs and their triggers are stored in memory
and loaded in via a YAML file.

1. Add a module

```elixir
defmodule MyApp.Engine do
  use Engine.Application, otp_app: :my_app
end
```

2. Add it to your supervision tree

```elixir
# application.ex
  def start(_type, _args) do

    children = [
      ...
      MyApp.Engine, [
        project_config: "file://" <> project_yaml_path,
        adaptors_path: Path.join(project_dir, "priv/openfn")
      ]
    ]

  end
```

3. Add calls to process messages

Wherever you need to process a message, for example in a Phoenix controller.
For example:

```elixir
  ...
  alias Engine.Message

  def receive(conn, _other) do
    body =
      conn
      |> Map.fetch!(:body_params)
      |> Jason.encode!()
      |> Jason.decode!()

    runs = Microservice.Engine.handle_message(%Message{body: body})

    {status, data} =
          {:accepted,
           %{
             "meta" => %{"message" => "Data accepted and processing has begun."},
             "data" => Enum.map(runs, fn run -> run.job.name end),
             "errors" => []
           }}

    conn
    |> put_status(status)
    |> json(data)
  end

  ...
```

4. Add some callbacks (optional)  
  ```elixir
  defmodule MyApp.GenericHandler do
    use Engine.Run.Handler
    require Logger

    def on_log_emit(str, _context) do
      Logger.debug("#{inspect(str)}")
    end
  end
```

## Running without a supervisor

It's possible to use Engine without it being in your supervision tree.
A common reason would be using some other queueing mechanism.


This can be achieved by calling `start/2` directly on a handler:

```elixir
defmodule MyApp.Handler do
  use Engine.Run.Handler
end

MyApp.Handler.start(run_spec)
# => %Result{...}
```

## Configuration

### A note on `adaptors_path`:

By default everything is installed into `$PWD/priv/openfn`.

> Currently with the `ShellRuntime` module, we require NPM modules to be installed
> in a global style. Just like with `npm install -g`, except we control where 
> those packages will be installed using the `--prefix` argument.
> Without using global installs you run the risk of new packages installed by
> Adaptor.Service overwriting _all_ currently installed packages.

## Callbacks

When using the Handler module, there are several callbacks that you can provide
to hook into various steps in the processing pipeline:

- `on_log_emit/2`  
  Log chunks as they come out of the Log Agent, strings are emitted for each
  complete grapheme (i.e. a complete and decodeable chunk of utf-8 data).
  Depending on the job being executed it is possible for this callback to be
  called quite a lot. It's up to you to buffer this up before forwarding.

- `on_start/1`  
  When a job is about to be processed, this is called with the context that was
  provided to it with `start/2`.

- `on_finish/2`  
  When a job is has ended, contains the `%Result{}` struct and context as
  arguments.

## Mix Tasks

- `openfn.install.runtime`  
  Assuming NodeJS is installed, it will install the latest versions of the most
  basic language packs.

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/openfn_engine](https://hexdocs.pm/openfn_engine).

