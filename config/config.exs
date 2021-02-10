import Config

config :openfn_engine,
       AppConfigured,
       project_config: "file://test/fixtures/project_config.yaml",
       name: Engine

# import_config "#{config_env()}.exs"
