defmodule ExampleStore do
  @behaviour Pegasus.Store
  defmacro __using__(_) do
  end
end

defmodule ExampleRepo do
  use Pegasus.Repo,
    otp_app: :test,
    store: ExampleStore
end

defmodule Pegasus.RepoTest do
  use ExUnit.Case
  doctest Pegasus.Repo
end
