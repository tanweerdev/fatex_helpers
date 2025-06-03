defmodule Fatex.FatContext do
  @moduledoc """
  Provides a comprehensive set of utility functions for common Ecto operations.

  This module offers a consistent API for CRUD operations, querying, and data manipulation
  when used within context modules.

  ## Features

  - Standardized CRUD operations
  - Flexible query building
  - Preloading support
  - Error handling patterns
  - Batch operations

  ## Usage

      defmodule MyApp.MyContext do
        use Fatex.FatContext, repo: MyApp.Repo

        # Add custom functions here
      end

  The module will then have access to all the utility functions.
  """

  defmacro __using__(opts) do
    quote location: :keep, bind_quoted: [opts: opts] do
      @repo opts[:repo] || raise(":repo option is required when using Fatex.FatContext")
      def repo, do: @repo

      # Runtime verification of repo
      @after_compile Fatex.FatContext

      import Ecto.Query, warn: false

      @doc """
      Retrieves the first record from the given schema.

      ## Options

      - `:order_by` - Field to order by (default: :id or :inserted_at if available)
      - `:preload` - Associations to preload (default: [])
      - `:where` - Additional where conditions

      ## Examples

          first(User)
          first(User, order_by: :name, preload: [:posts])
      """
      @spec first(module(), keyword()) :: struct() | nil
      def first(schema, opts \\ []) do
        schema
        |> base_query(opts)
        |> maybe_order_by_first(opts)
        |> limit(1)
        |> repo().one()
        |> maybe_preload(opts[:preload])
      end

      @doc """
      Retrieves the last record from the given schema.

      ## Options

      - `:order_by` - Field to order by (default: :id or :inserted_at if available)
      - `:preload` - Associations to preload (default: [])
      - `:where` - Additional where conditions

      ## Examples

          last(User)
          last(User, order_by: :name, preload: [:posts])
      """
      @spec last(module(), keyword()) :: struct() | nil
      def last(schema, opts \\ []) do
        schema
        |> base_query(opts)
        |> maybe_order_by_last(opts)
        |> limit(1)
        |> repo().one()
        |> maybe_preload(opts[:preload])
      end

      @doc """
      Counts records matching given conditions.

      ## Options

      - `:where` - Conditions to filter by

      ## Examples

          count(User)
          count(User, where: [active: true])
      """
      @spec count(module(), keyword()) :: integer()
      def count(schema, opts \\ []) do
        schema
        |> base_query(opts)
        |> select([q], fragment("COUNT(*)"))
        |> repo().one()
      end

      @doc """
      Lists all records with optional filtering and preloading.

      ## Options

      - `:where` - Conditions to filter by
      - `:preload` - Associations to preload
      - `:order_by` - Field(s) to order by
      - `:limit` - Maximum number of records to return
      - `:offset` - Number of records to skip

      ## Examples

          list(User)
          list(User, where: [active: true], preload: [:posts])
      """
      @spec list(module(), keyword()) :: list(struct())
      def list(schema, opts \\ []) do
        schema
        |> base_query(opts)
        |> maybe_order_by(opts[:order_by])
        |> maybe_limit(opts[:limit])
        |> maybe_offset(opts[:offset])
        |> repo().all()
        |> maybe_preload(opts[:preload])
      end

      @doc """
      Gets a record by ID with error handling.

      ## Options

      - `:preload` - Associations to preload

      ## Examples

          get(User, 1)
          get(User, 1, preload: [:posts])
      """
      @spec get(module(), term(), keyword()) :: {:ok, struct()} | {:error, :not_found}
      def get(schema, id, opts \\ []) do
        case repo().get(schema, id) do
          nil -> {:error, :not_found}
          record -> {:ok, maybe_preload(record, opts[:preload])}
        end
      end

      @doc """
      Gets a record by ID or raises if not found.

      ## Options

      - `:preload` - Associations to preload

      ## Examples

          get!(User, 1)
          get!(User, 1, preload: [:posts])
      """
      @spec get!(module(), term(), keyword()) :: struct() | no_return()
      def get!(schema, id, opts \\ []) do
        schema
        |> repo().get!(id)
        |> maybe_preload(opts[:preload])
      end

      @doc """
      Gets a record by conditions with error handling.

      ## Options

      - `:preload` - Associations to preload

      ## Examples

          get_by(User, email: "test@example.com")
          get_by(User, [email: "test@example.com"], preload: [:posts])
      """
      @spec get_by(module(), keyword() | map(), keyword()) :: {:ok, struct()} | {:error, :not_found}
      def get_by(schema, clauses, opts \\ []) do
        case repo().get_by(schema, clauses) do
          nil -> {:error, :not_found}
          record -> {:ok, maybe_preload(record, opts[:preload])}
        end
      end

      @doc """
      Creates a record with the given attributes.

      ## Options

      - All Ecto.Repo.insert/2 options

      ## Examples

          create(User, %{name: "John"})
      """
      @spec create(module(), map(), keyword()) :: {:ok, struct()} | {:error, Ecto.Changeset.t()}
      def create(schema, attrs, opts \\ []) do
        struct = schema.__struct__()
        changeset = schema.changeset(struct, attrs)
        repo().insert(changeset, opts)
      end

      @doc """
      Creates a record with the given attributes or raises on error.

      ## Options

      - All Ecto.Repo.insert!/2 options

      ## Examples

          create!(User, %{name: "John"})
      """
      @spec create!(module(), map(), keyword()) :: struct() | no_return()
      def create!(schema, attrs, opts \\ []) do
        struct = schema.__struct__()
        changeset = schema.changeset(struct, attrs)
        repo().insert!(changeset, opts)
      end

      @doc """
      Updates a record with the given attributes.

      ## Options

      - All Ecto.Repo.update/2 options

      ## Examples

          update(user, User, %{name: "New Name"})
      """
      @spec update(struct(), module(), map(), keyword()) :: {:ok, struct()} | {:error, Ecto.Changeset.t()}
      def update(record, schema, attrs, opts \\ []) do
        record
        |> schema.changeset(attrs)
        |> repo().update(opts)
      end

      @doc """
      Updates a record with the given attributes or raises on error.

      ## Options

      - All Ecto.Repo.update!/2 options

      ## Examples

          update!(user, User, %{name: "New Name"})
      """
      @spec update!(struct(), module(), map(), keyword()) :: struct() | no_return()
      def update!(record, schema, attrs, opts \\ []) do
        record
        |> schema.changeset(attrs)
        |> repo().update!(opts)
      end

      @doc """
      Deletes a record.

      ## Options

      - All Ecto.Repo.delete/2 options

      ## Examples

          delete(user)
      """
      @spec delete(struct(), keyword()) :: {:ok, struct()} | {:error, Ecto.Changeset.t()}
      def delete(record, opts \\ []) do
        repo().delete(record, opts)
      end

      @doc """
      Deletes all records matching conditions.

      ## Options

      - `:where` - Conditions to filter by

      ## Examples

          delete_all(User)
          delete_all(User, where: [active: false])
      """
      @spec delete_all(module(), keyword()) :: {integer(), nil | [term()]}
      def delete_all(schema, opts \\ []) do
        schema
        |> base_query(opts)
        |> repo().delete_all()
      end

      @doc """
      Creates a changeset for the given record and attributes.

      ## Examples

          changeset(User, user, %{name: "New Name"})
      """
      @spec changeset(module(), struct(), map()) :: Ecto.Changeset.t()
      def changeset(schema, record, attrs \\ %{}) do
        schema.changeset(record, attrs)
      end

      @doc """
      Creates or updates a record based on conditions.

      ## Options

      - `:on_conflict` - Conflict resolution strategy
      - `:conflict_target` - Conflict target fields
      - Other Ecto.Repo.insert/2 options

      ## Examples

          upsert(User, [email: "test@example.com"], %{name: "Updated"}, %{name: "New", email: "test@example.com"})
      """
      @spec upsert(module(), keyword() | map(), map(), map(), keyword()) ::
              {:ok, struct()} | {:error, Ecto.Changeset.t()}
      def upsert(schema, conditions, update_attrs, create_attrs, opts \\ []) do
        case get_by(schema, conditions) do
          {:ok, record} -> update(record, schema, update_attrs, opts)
          {:error, :not_found} -> create(schema, create_attrs, opts)
        end
      end

      # Private helper functions

      defp base_query(schema, opts) do
        query = from(q in schema)

        case Keyword.get(opts, :where) do
          nil -> query
          conditions -> where(query, ^conditions)
        end
      end

      defp maybe_order_by(query, nil), do: query
      defp maybe_order_by(query, fields) when is_list(fields), do: order_by(query, ^fields)
      defp maybe_order_by(query, field), do: order_by(query, [q], field(q, ^field))

      defp maybe_order_by_first(query, opts) do
        case Keyword.get(opts, :order_by) do
          nil ->
            cond do
              has_field?(query, :id) -> order_by(query, [q], asc: q.id)
              has_field?(query, :inserted_at) -> order_by(query, [q], asc: q.inserted_at)
              true -> query
            end
          field ->
            order_by(query, [q], asc: field(q, ^field))
        end
      end

      defp maybe_order_by_last(query, opts) do
        case Keyword.get(opts, :order_by) do
          nil ->
            cond do
              has_field?(query, :id) -> order_by(query, [q], desc: q.id)
              has_field?(query, :inserted_at) -> order_by(query, [q], desc: q.inserted_at)
              true -> query
            end
          field ->
            order_by(query, [q], desc: field(q, ^field))
        end
      end

      defp maybe_limit(query, nil), do: query
      defp maybe_limit(query, limit), do: limit(query, ^limit)

      defp maybe_offset(query, nil), do: query
      defp maybe_offset(query, offset), do: offset(query, ^offset)

      defp maybe_preload(nil, _), do: nil
      defp maybe_preload(record, nil), do: record
      defp maybe_preload(record, preloads), do: repo().preload(record, preloads)

      defp has_field?(query, field) do
        schema = query.from.source |> elem(1)
        Enum.member?(schema.__schema__(:fields), field)
      end
    end
  end

  @doc """
  Runtime verification of the repository module.
  """
  def __after_compile__(%{module: module}, _bytecode) do
    repo = module.repo()

    unless Code.ensure_loaded?(repo) and function_exported?(repo, :__adapter__, 0) do
      raise ArgumentError, """
      The provided :repo option is not a valid Ecto.Repo.
      Expected a module that implements Ecto.Repo behaviour, got: #{inspect(repo)}
      """
    end
  end
end
