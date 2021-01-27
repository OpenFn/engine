defmodule OpenFn.Engine.MixProject do
  use Mix.Project

  def project do
    [
      app: :openfn_engine,
      version: "0.1.0",
      elixir: "~> 1.10",
      start_permanent: Mix.env() == :prod,
      deps: deps(),

      # Docs
      name: "OpenFn.Engine",
      source_url: "https://github.com/OpenFn/engine",
      # homepage_url: "http://YOUR_PROJECT_HOMEPAGE",
      docs: docs()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {OpenFn.Engine.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:ex_doc, "~> 0.22", only: :dev, runtime: false},
      {:exjsonpath, "~> 0.1"},
      {:mix_test_watch, "~> 1.0", only: :dev, runtime: false},
      {:rambo, "~> 0.3.2"},
      {:temp, "~> 0.4"},
      {:yaml_elixir, "~> 2.5"}
      # {:dep_from_hexpm, "~> 0.3.0"},
      # {:dep_from_git, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"}
    ]
  end

  defp docs do
    [
      main: "readme",
      # logo: "path/to/logo.png",
      extras: [
        "README.md",
        "LICENSE"
      ],
      source_ref: "v#{@version}",
      source_url: @source_url
    ]
  end
end
