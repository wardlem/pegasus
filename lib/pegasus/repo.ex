defmodule Pegasus.Repo do
  @moduledoc """
  Defines the behavior for the interface between the Pegaus ORM and the underlying datastore.
  """

  @defaults [timeout: 15000, pool_size: 10]

  @doc """
  Processes the compile time configuration.
  """
  def compile_config(opts) do
    otp_app = Keyword.fetch!(opts, :otp_app)
    store = opts[:store]

    unless store do
      raise ArgumentError, "Pegasus.Repo requires a :store option"
    end

    unless Code.ensure_compiled?(store) do
      raise ArgumentError,
            "store #{inspect(store)} was not compiled, " <>
              "ensure it is correct and it is included as a project dependency"
    end

    behaviours =
      for {:behaviour, behaviours} <- store.__info__(:attributes),
          behaviour <- behaviours,
          do: behaviour

    unless Pegasus.Store in behaviours do
      raise ArgumentError,
            "the :store option given to Pegasus.Repo must reference a Pegasus.Store implementation"
    end

    {otp_app, store}
  end

  @doc """
  Retrieves the runtime configuration.
  """
  def runtime_config(type, repo, otp_app, options) do
    config = Application.get_env(otp_app, repo, [])
    config = [otp_app: otp_app] ++ (@defaults |> Keyword.merge(config) |> Keyword.merge(options))

    case repo_init(type, repo, config) do
      {:ok, config} ->
        validate_config!(repo, config)
        {:ok, config}
    end
  end

  @doc false
  defp validate_config!(_repo, _config) do
    # intentionally left blank
  end

  @doc false
  defp repo_init(type, repo, config) do
    if Code.ensure_loaded?(repo) and function_exported?(repo, :init, 2) do
      repo.init(type, config)
    else
      {:ok, config}
    end
  end

  @type t :: module

  @doc false
  defmacro __using__(opts) do
    quote bind_quoted: [opts: opts] do
      @behaviour Pegasus.Repo

      {otp_app, store} = Pegasus.Repo.compile_config(opts)

      @otp_app otp_app
      @store store

      def config do
        {:ok, config} = Ecto.Repo.runtime_config(:runtime, __MODULE__, @otp_app, [])
        config
      end

      def __store__ do
        @store
      end

      def find_one(collection, filter, options \\ []) do
        options = [{:limit, 1} | options]
        res = apply(__MODULE__, :find_many, [collection, filter, options])

        case res do
          {:ok, [hd | tl]} -> {:ok, hd}
          {:ok, []} -> {:ok, nil}
          _ -> res
        end
      end

      def find_many(collection, filter, options \\ []) do
        raise "the find many operation is not supported by this repo"
      end

      def stream(collection, filter, options \\ []) do
        raise "the stream operation is not supported by this repo"
      end

      def count(collection, filter, options \\ []) do
        raise "the count operation is not supported by this repo"
      end

      def insert_one(collection, item, options \\ []) do
        res = apply(__MODULE__, :insert_many, [collection, [item], options])

        case res do
          {:ok, [hd | tl]} -> {:ok, hd}
          {:ok, []} -> {:ok, nil}
          _ -> res
        end
      end

      def insert_many(collection, items, options \\ []) do
        raise "the insert many operation is not supported by this repo"
      end

      def update_one(collection, filter, updates, options \\ []) do
        options = [{:limit, 1} | options]
        res = apply(__MODULE__, :update_many, [collection, filter, updates, options])

        case res do
          {:ok, [hd | tl]} -> {:ok, hd}
          {:ok, []} -> {:ok, nil}
          _ -> res
        end
      end

      def update_many(collection, filter, updates, options \\ []) do
        raise "the update many operation is not supported by this repo"
      end

      def insert_or_update_one(collection, unique_key, updates, options \\ []) do
        options = [{:limit, 1} | options]

        res =
          apply(__MODULE__, :insert_or_update_many, [collection, unique_key, updates, options])

        case res do
          {:ok, [hd | tl]} -> {:ok, hd}
          {:ok, []} -> {:ok, nil}
          _ -> res
        end
      end

      def insert_or_update_many(collection, unique_key, updates, options \\ []) do
        raise "the insert or update many operation is not supported by this repo"
      end

      def delete_one(collection, filter, options \\ []) do
        options = [{:limit, 1} | options]
        apply(__MODULE__, :delete_many, [collection, filter, options])
      end

      def delete_many(collection, filter, options \\ []) do
        raise "the delete many operation is not supported by this repo"
      end

      defmacro storage_types, do: []

      defoverridable Pegasus.Repo

      @use store
    end
  end

  @doc """
  Returns the store configuration stored in the `:otp_app` environment.
  """
  @callback config() :: keyword

  @doc """
  Get the store for the repo.
  """
  @callback __store__() :: Pegasus.Store.t()

  @doc """
  Retrieve a single record from the datastore collection.
  """
  @callback find_one(collection :: String.t(), filter :: keyword, options :: keyword) ::
              {:ok, any} | {:error, String.t()}
  @doc """
  Retrieve multiple records from a datastore collection.
  """
  @callback find_many(collection :: String.t(), filter :: keyword, options :: keyword) ::
              {:ok, [any]} | {:error, String.t()}
  @doc """
  Retrieve multiple records from a datastore collection and return as a stream.
  """
  @callback stream(collection :: String.t(), filter :: keyword, options :: keyword) ::
              {:ok, Enum.t()} | {:error, String.t()}
  @doc """
  Count the records in a datastore collection that match a filter.
  """
  @callback count(collection :: String.t(), filter :: keyword, options :: keyword) ::
              {:ok, integer} | {:error, String.t()}

  @doc """
  Insert a single record into a datastore collection.
  """
  @callback insert_one(collection :: String.t(), item :: any, options :: keyword) ::
              {:ok, any} | {:error, String.t()}
  @doc """
  Insert multiple records into a datastore collection.
  """
  @callback insert_many(collection :: String.t(), items :: [any], options :: keyword) ::
              {:ok, [any]} | {:error, String.t()}
  @doc """
  Update a single record in a datastore collection.
  """
  @callback update_one(
              collection :: String.t(),
              filter :: keyword,
              updates :: keyword,
              options :: keyword
            ) ::
              {:ok, any} | {:error, String.t()}
  @doc """
  Update multiple records in a datastore collection.
  """
  @callback update_many(
              collection :: String.t(),
              filter :: keyword,
              updates :: keyword,
              options :: keyword
            ) ::
              {:ok, any} | {:error, String.t()}
  @doc """
  Insert or update a single record in a datastore collection.
  """
  @callback insert_or_update_one(
              collection :: String.t(),
              unique_key :: atom,
              updates :: keyword,
              options :: keyword
            ) ::
              {:ok, any} | {:error, String.t()}
  @doc """
  Insert or update multiple records in a datastore collection.
  """
  @callback insert_or_update_many(
              collection :: String.t(),
              unique_key :: atom,
              updates :: keyword,
              options :: keyword
            ) ::
              {:ok, [any]} | {:error, String.t()}

  @doc """
  Delete a single record from a datastore collection.
  """
  @callback delete_one(
              collection :: String.t(),
              filter :: keyword,
              options :: keyword
            ) :: {:ok, integer} | {:error, String.t()}
  @doc """
  Delete multiple records from a datastore collection.
  """
  @callback delete_many(
              collection :: String.t(),
              filter :: keyword,
              options :: keyword
            ) :: {:ok, integer} | {:error, String.t()}
  @doc """
  Gets a list of supported storage types.

  This is used for negotiating conversion types between ORM schema property
  types and the types the repo supports.
  """
  @macrocallback storage_types() :: [atom]
end
