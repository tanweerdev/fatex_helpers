defmodule Fatex.FatDataSanitizer do
  @moduledoc """
  Provides comprehensive data sanitization and transformation capabilities.

  ## Features

  - Field masking for sensitive data
  - Selective field inclusion/exclusion
  - Deep sanitization of nested structures
  - Support for Ecto schemas and raw maps
  - Customizable sanitization rules

  ## Usage

      defmodule MyApp.DataUtils do
        use Fatex.FatDataSanitizer

        # Optionally override any sanitization functions
      end

  ## Options

  - `:mask` - Fields to mask with replacement values (e.g., `[password: "********"]`)
  - `:remove` - Fields to completely remove from output
  - `:only` - Whitelist of fields to include
  - `:except` - Blacklist of fields to exclude
  - `:deep` - Whether to recursively sanitize nested structures (default: true)
  """

  defmacro __using__(_opts) do
    quote location: :keep do
      @doc """
      Sanitizes data by applying transformation rules.

      Supports:
      - Single records (maps or structs)
      - Lists of records
      - Nested data structures
      - Tuples (converted to maps or JSON)

      ## Examples

          # Basic sanitization
          sanitize(%{name: "John", password: "secret"}, remove: [:password])

          # Masking sensitive data
          sanitize(user, mask: [email: "****@****", password: "********"])

          # Selective field inclusion
          sanitize(user, only: [:name, :email])
      """
      @spec sanitize(
              map() | list(map()) | tuple() | struct(),
              keyword()
            ) :: map() | list(map())
      def sanitize(data, opts \\ [])

      def sanitize(records, opts) when is_list(records) do
        Enum.map(records, &sanitize_record(&1, opts))
      end

      def sanitize(record, opts) when is_tuple(record) do
        sanitize_tuple(record, opts)
      end

      def sanitize(%_{} = record, opts) do
        record
        |> Map.from_struct()
        |> sanitize_record(opts)
      end

      def sanitize(record, opts) when is_map(record) do
        sanitize_record(record, opts)
      end

      def sanitize(record, _opts), do: record

      @doc """
      Sanitizes a single record with the given options.
      """
      @spec sanitize_record(map() | struct(), keyword()) :: map()
      def sanitize_record(record, opts) do
        record
        |> prepare_record()
        |> remove_keys(opts[:remove])
        |> mask_values(opts[:mask])
        |> filter_keys(opts[:only], opts[:except])
        |> maybe_deep_sanitize(opts)
      end

      defp prepare_record(%_{} = record), do: Map.from_struct(record)
      defp prepare_record(record), do: record

      @doc """
      Handles sanitization of tuple records.
      """
      @spec sanitize_tuple(tuple(), keyword()) :: map() | binary()
      def sanitize_tuple(record, opts) when is_tuple(record) do
        case tuple_size(record) do
          2 ->
            {key, value} = record
            %{key => sanitize(value, opts)}

          _size ->
            case Application.get_env(:fatex_helpers, :json_library, Jason) do
              nil ->
                raise "Please configure :json_library in :fatex_helpers application environment"

              encoder ->
                record
                |> Tuple.to_list()
                |> encoder.encode!(encoder_opts(encoder))
            end
        end
      end

      defp encoder_opts(Jason), do: []
      defp encoder_opts(_), do: []

      @doc """
      Recursively sanitizes nested map structures.
      """
      @spec sanitize_map(map(), keyword()) :: map()
      def sanitize_map(record, opts) when is_map(record) do
        Enum.reduce(record, %{}, fn {k, v}, acc ->
          cond do
            # Skip unloaded associations
            match?(%Ecto.Association.NotLoaded{}, v) ->
              acc

            Keyword.get(opts, :deep, true) ->
              Map.put(acc, k, sanitize(v, opts))

            true ->
              Map.put(acc, k, v)
          end
        end)
      end

      @doc """
      Removes specified keys from a record.
      """
      @spec remove_keys(map(), list(atom()) | nil) :: map()
      def remove_keys(record, nil), do: record
      def remove_keys(record, []), do: record

      def remove_keys(record, keys_to_remove) when is_list(keys_to_remove) do
        Map.drop(record, keys_to_remove)
      end

      @doc """
      Masks specified values in a record.
      """
      @spec mask_values(map(), keyword() | nil) :: map()
      def mask_values(record, nil), do: record
      def mask_values(record, []), do: record

      def mask_values(record, mask_rules) when is_list(mask_rules) do
        Enum.reduce(mask_rules, record, fn {key, mask}, acc ->
          if Map.has_key?(acc, key), do: Map.put(acc, key, mask), else: acc
        end)
      end

      @doc """
      Filters keys based on inclusion/exclusion rules.
      """
      @spec filter_keys(map(), list(atom()) | nil, list(atom()) | nil) :: map()
      def filter_keys(record, nil, nil), do: record
      def filter_keys(record, [], nil), do: record
      def filter_keys(record, nil, []), do: record

      def filter_keys(record, only_keys, nil) when is_list(only_keys) do
        Map.take(record, only_keys)
      end

      def filter_keys(record, nil, except_keys) when is_list(except_keys) do
        Map.drop(record, except_keys)
      end

      def filter_keys(record, _only_keys, _except_keys), do: record

      defp maybe_deep_sanitize(record, opts) do
        if Keyword.get(opts, :deep, true) do
          sanitize_map(record, opts)
        else
          record
        end
      end

      defoverridable sanitize: 2,
                     sanitize_record: 2,
                     sanitize_tuple: 2,
                     sanitize_map: 2,
                     remove_keys: 2,
                     mask_values: 2,
                     filter_keys: 3
    end
  end
end
