defmodule OpenFn.Engine.Application do
  @moduledoc false

  defmacro __using__(opts) do
    quote bind_quoted: [opts: opts] do
      # Default the name of this app to the module
      @mod_options Keyword.merge([name: __MODULE__], opts)

      def child_spec(opts) do
        %{
          id: __MODULE__,
          start: {__MODULE__, :start_link, [opts]},
          type: :supervisor
        }
      end

      def start_link(opts \\ []) do
        opts = Keyword.merge(@mod_options, opts)

        OpenFn.Engine.Supervisor.start_link(opts)
      end

      alias OpenFn.Message

      def handle_message(%Message{} = message) do
        OpenFn.Engine.handle_message(project_config!, message)
      end

      defp config(key) when is_atom(key) do
        OpenFn.Engine.config(@mod_options[:name], key)
      end

      defp project_config! do
        config(:project_config) ||
          raise ArgumentError, "no :project_config configured for #{inspect(__MODULE__)}"
      end
    end
  end
end
