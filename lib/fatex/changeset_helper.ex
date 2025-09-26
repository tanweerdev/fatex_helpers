defmodule Fatex.ChangesetHelper do
  @moduledoc """
  Provides utility functions for validating Ecto changesets with advanced validation rules.

  ## Common Validation Patterns

  - Exclusive fields (XOR): Only one field in a set may be present
  - Required fields: Validate presence based on conditions
  - Temporal validation: Validate date/time relationships
  - Field dependencies: Validate fields based on other fields' presence

  ## Examples

      # Exclusive fields validation
      changeset
      |> validate_exclusive_fields([:email, :phone])

      # Temporal validation
      changeset
      |> validate_start_before_end(:start_time, :end_time, compare_type: :time)
  """

  import Ecto.Changeset

  @doc """
  Validates that only one of the specified fields is present (exclusive fields).

  ## Options

  - `:error_message` - Custom error message when multiple fields are present
  - `:required_message` - Custom message when no fields are present
  - `:treat_values_present` - List of values to treat as present (e.g., [nil])
  - `:treat_values_absent` - List of values to treat as absent/not present (e.g., [0.0, 0, ""])

  ## Value Handling

  By default, only non-nil values are considered present. The options modify this behavior:

  - `nil` values are treated as absent by default
  - Empty strings (`""`) are treated as present by default (non-nil)
  - Zero values (`0`, `0.0`) are treated as present by default (non-nil)
  - Use `treat_values_absent` to make specific values (like `""`, `0`) count as absent
  - Use `treat_values_present` to make specific values (like `nil`) count as present
  - If a value appears in both lists, `treat_values_absent` takes precedence

  ## Examples

      # Basic usage
      validate_exclusive_fields(changeset, [:email, :phone])

      # With custom messages
      validate_exclusive_fields(changeset, [:email, :phone],
        error_message: "Provide either email or phone, not both",
        required_message: "Either email or phone is required"
      )

      # Treat empty strings and zeros as absent
      validate_exclusive_fields(changeset, [:amount, :percentage],
        treat_values_absent: [0.0, 0, ""]
      )

      # Treat nil as present (explicit nil value)
      validate_exclusive_fields(changeset, [:value_a, :value_b],
        treat_values_present: [nil]
      )

      # Common pattern: treat \"empty\" values as absent
      validate_exclusive_fields(changeset, [:email, :phone],
        treat_values_absent: [nil, \"\", 0]
      )
  """
  @spec validate_exclusive_fields(Ecto.Changeset.t(), list(atom()), keyword()) :: Ecto.Changeset.t()
  def validate_exclusive_fields(changeset, fields, opts \\ []) do
    error_msg = opts[:error_message] || "#{humanize_fields(fields)} are mutually exclusive"
    required_msg = opts[:required_message] || "At least one of #{humanize_fields(fields)} is required"
    treat_present = Keyword.get(opts, :treat_values_present, [])
    treat_absent = Keyword.get(opts, :treat_values_absent, [])

    present_fields =
      fields
      |> Enum.filter(&field_present?(changeset, &1, treat_present, treat_absent))
      |> length()

    cond do
      present_fields > 1 ->
        add_mutual_exclusion_errors(changeset, fields, error_msg)

      present_fields == 0 ->
        add_requirement_errors(changeset, fields, required_msg)

      true ->
        changeset
    end
  end

  @doc """
  Validates that exactly one of the specified fields is present.

  ## Options

  - `:message` - Custom error message
  - `:treat_values_present` - List of values to treat as present (e.g., [nil])
  - `:treat_values_absent` - List of values to treat as absent/not present (e.g., [0.0, 0, ""])

  ## Value Handling

  See `validate_exclusive_fields/3` for details on how values are treated as present or absent.

  ## Examples

      validate_exactly_one_field(changeset, [:card_number, :card_token])

      # With treat options
      validate_exactly_one_field(changeset, [:amount, :percentage],
        treat_values_absent: [0.0, 0, ""]
      )
  """
  @spec validate_exactly_one_field(Ecto.Changeset.t(), list(atom()), keyword()) :: Ecto.Changeset.t()
  def validate_exactly_one_field(changeset, fields, opts \\ []) do
    message = opts[:message] || "Exactly one of #{humanize_fields(fields)} is required"
    treat_present = Keyword.get(opts, :treat_values_present, [])
    treat_absent = Keyword.get(opts, :treat_values_absent, [])

    present_count =
      fields
      |> Enum.filter(&field_present?(changeset, &1, treat_present, treat_absent))
      |> length()

    case present_count do
      1 -> changeset
      _ -> add_requirement_errors(changeset, fields, message)
    end
  end

  @doc """
  Validates that at least one of the specified fields is present.

  ## Options

  - `:message` - Custom error message
  - `:treat_values_present` - List of values to treat as present (e.g., [nil])
  - `:treat_values_absent` - List of values to treat as absent/not present (e.g., [0.0, 0, ""])

  ## Value Handling

  See `validate_exclusive_fields/3` for details on how values are treated as present or absent.

  ## Examples

      validate_any_field_present(changeset, [:email, :phone, :username])

      # Treat empty values as absent
      validate_any_field_present(changeset, [:first_name, :last_name, :display_name],
        treat_values_absent: ["", nil]
      )
  """
  @spec validate_any_field_present(Ecto.Changeset.t(), list(atom()), keyword()) :: Ecto.Changeset.t()
  def validate_any_field_present(changeset, fields, opts \\ []) do
    message = opts[:message] || "At least one of #{humanize_fields(fields)} is required"
    treat_present = Keyword.get(opts, :treat_values_present, [])
    treat_absent = Keyword.get(opts, :treat_values_absent, [])

    if Enum.any?(fields, &field_present?(changeset, &1, treat_present, treat_absent)) do
      changeset
    else
      add_requirement_errors(changeset, fields, message)
    end
  end

  @doc """
  Makes a field required if another field is present in the changeset.

  ## Options

  - `:message` - Custom error message when field is required but missing

  ## Examples

      require_field_if_present(changeset, if_present: :email, require: :email_verified)
  """
  @spec require_field_if_present(Ecto.Changeset.t(), keyword()) :: Ecto.Changeset.t()
  def require_field_if_present(changeset, opts) do
    if_present = Keyword.fetch!(opts, :if_present)
    require = Keyword.fetch!(opts, :require)
    message = Keyword.get(opts, :message, "can't be blank")

    if field_present?(changeset, if_present, [], []) do
      validate_required(changeset, [require], message: message)
    else
      changeset
    end
  end

  @doc """
  Validates that a start date/time is before an end date/time.

  ## Options

  - `:compare_type` - Either `:time` or `:datetime` (default: `:datetime`)
  - `:message` - Custom error message
  - `:field` - Which field to attach the error to (default: `start_field`)

  ## Examples

      validate_start_before_end(changeset, :starts_at, :ends_at, compare_type: :datetime)
  """
  @spec validate_start_before_end(Ecto.Changeset.t(), atom(), atom(), keyword()) :: Ecto.Changeset.t()
  def validate_start_before_end(changeset, start_field, end_field, opts \\ []) do
    start_value = get_field(changeset, start_field)
    end_value = get_field(changeset, end_field)
    compare_type = Keyword.get(opts, :compare_type, :datetime)
    message = Keyword.get(opts, :message, "must be before #{end_field}")
    error_field = Keyword.get(opts, :field, start_field)

    if start_value && end_value && !before?(start_value, end_value, compare_type) do
      add_changeset_error(changeset, error_field, message)
    else
      changeset
    end
  end

  @doc """
  Validates that a start date/time is before or equal to an end date/time.

  ## Options

  - `:compare_type` - Either `:time` or `:datetime` (default: `:datetime`)
  - `:message` - Custom error message
  - `:field` - Which field to attach the error to (default: `start_field`)

  ## Examples

      validate_start_before_or_equal_end(changeset, :starts_at, :ends_at)
  """
  @spec validate_start_before_or_equal_end(Ecto.Changeset.t(), atom(), atom(), keyword()) ::
          Ecto.Changeset.t()
  def validate_start_before_or_equal_end(changeset, start_field, end_field, opts \\ []) do
    start_value = get_field(changeset, start_field)
    end_value = get_field(changeset, end_field)
    compare_type = Keyword.get(opts, :compare_type, :datetime)
    message = Keyword.get(opts, :message, "must be before or equal to #{end_field}")
    error_field = Keyword.get(opts, :field, start_field)

    if start_value && end_value && !before_or_equal?(start_value, end_value, compare_type) do
      add_changeset_error(changeset, error_field, message)
    else
      changeset
    end
  end

  @doc """
  Adds a custom error to the changeset.

  ## Examples

      add_changeset_error(changeset, :email, "invalid format")
  """
  @spec add_changeset_error(Ecto.Changeset.t(), atom(), String.t()) :: Ecto.Changeset.t()
  def add_changeset_error(changeset, field, message) do
    Ecto.Changeset.add_error(changeset, field, message)
  end

  # Private helper functions

  defp field_present?(changeset, field, treat_present, treat_absent) do
    value = get_field(changeset, field)

    cond do
      value in treat_absent -> false
      value in treat_present -> true
      not is_nil(value) -> true
      true -> false
    end
  end

  defp add_mutual_exclusion_errors(changeset, fields, message) do
    Enum.reduce(fields, changeset, &add_changeset_error(&2, &1, message))
  end

  defp add_requirement_errors(changeset, fields, message) do
    Enum.reduce(fields, changeset, fn field, cs ->
      add_changeset_error(cs, field, message)
    end)
  end

  defp humanize_fields(fields) do
    Enum.map_join(fields, ", ", &Atom.to_string/1)
  end

  defp before?(start_date, end_date, :time), do: Time.diff(start_date, end_date) < 0
  defp before?(start_date, end_date, _), do: DateTime.diff(start_date, end_date) < 0

  defp before_or_equal?(start_date, end_date, :time), do: Time.diff(start_date, end_date) <= 0
  defp before_or_equal?(start_date, end_date, _), do: DateTime.diff(start_date, end_date) <= 0
end
