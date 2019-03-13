defmodule Pegasus do
  @moduledoc """
  Documentation for Pegasus.
  """

  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications

  use Application

  def start(_type, _args) do
    # List all child processes to be supervised
    children = [
      # Starts a worker by calling: Pegasus.Worker.start_link(arg)
      # {Pegasus.Worker, arg}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Pegasus.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
