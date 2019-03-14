defmodule Pegasus.Ext do
  defmacro __using__(_) do
    quote do
      def name do
        Atom.to_string(__MODULE__)
        |> String.replace_prefix("Elixir.", "")
      end

      defoverridable name: 0
    end
  end
end
