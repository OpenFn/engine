defmodule OpenFn.Engine.Application do
  @moduledoc false

  defmacro __using__(opts) do
    quote bind_quoted: [opts: opts] do
      # Default the name of this app to the module
      @otp_app opts[:otp_app] || raise "engine expects :otp_app to be given"
      @config OpenFn.Engine.Supervisor.config @otp_app, __MODULE__, opts

      def child_spec(opts) do
        IO.inspect(["child_spec/1",opts], label: "__using__")
        %{
          id: @config[:name],
          start: {__MODULE__, :start_link, [opts]},
          type: :supervisor
        }
      end

      def start_link(opts \\ []) do
        IO.inspect(["start_link/1", opts], label: "__using__")

        OpenFn.Engine.Supervisor.start_link(@config)
      end

      alias OpenFn.Message

      def handle_message(%Message{} = message) do
        OpenFn.Engine.handle_message(project_config!(), message)
      end

      defp config(key) when is_atom(key) do
        OpenFn.Engine.config(@config[:name], key)
      end

      defp project_config! do
        config(:project_config) ||
          raise ArgumentError, "no :project_config configured for #{inspect(__MODULE__)}"
      end
    end
  end
end
