defmodule OpenFn.Engine.Application do
  @moduledoc false

  defmacro __using__(opts) do
    quote bind_quoted: [opts: opts] do
      @otp_app opts[:otp_app] || raise "engine expects :otp_app to be given"
      @config OpenFn.Engine.Supervisor.config @otp_app, __MODULE__, opts

      def child_spec(opts) do
        %{
          id: @config[:name],
          start: {__MODULE__, :start_link, [opts]},
          type: :supervisor
        }
      end

      def start_link(opts \\ []) do
        OpenFn.Engine.Supervisor.start_link(@config)
      end

      alias OpenFn.{Message, Job}

      def handle_message(%Message{} = message) do
        OpenFn.Engine.handle_message(@config[:run_broadcaster_name], message)
      end

      def get_job_state(%Job{} = job) do
        OpenFn.Engine.get_job_state(@config[:job_state_repo_name], job)
      end

      def config(key) when is_atom(key) do
        @config[key]
      end

      defp project_config! do
        config(:project_config) ||
          raise ArgumentError, "no :project_config configured for #{inspect(__MODULE__)}"
      end
    end
  end
end
