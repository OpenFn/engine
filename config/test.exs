import Config

config :engine,
       AppConfigured,
       project_config: "file://test/fixtures/project_config.yaml",
       name: Engine

config :junit_formatter,
  report_file: "report_file_test.xml",
  report_dir: "./tmp",
  print_report_file: true,
  prepend_project_name?: true

# config :logger, level: :debug
