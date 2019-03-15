defmodule Pegasus.Ext do
  @moduledoc """
  Defines a *Pegasus* extension.

  Extensions are the mechanism through which functionality is added to
  a *Pegasus* application.
  For example, an extension may provide any of the following:

  - A repository for the ORM
  - A schema type
  - A model
  - A good many other things
  """
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
