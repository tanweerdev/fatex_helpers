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
  - `:allow_nil` - If true, treats nil values as not present (default: false)

  ## Examples

      # Basic usage
      validate_exclusive_fields(changeset, [:email, :phone])

      # With custom messages
      validate_exclusive_fields(changeset, [:email, :phone],
        error_message: "Provide either email or phone, not both",
        required_message: "Either email or phone is required"
      )
  """
  @spec validate_exclusive_fields(Ecto.Changeset.t(), list(atom()), keyword()) :: Ecto.Changeset.t()
  def validate_exclusive_fields(changeset, fields, opts \\ []) do
    error_msg = opts[:error_message] || "#{humanize_fields(fields)} are mutually exclusive"
    required_msg = opts[:required_message] || "At least one of #{humanize_fields(fields)} is required"
    allow_nil? = Keyword.get(opts, :allow_nil, false)

    present_fields =
      fields
      |> Enum.filter(&field_present?(changeset, &1, allow_nil?))
      |> length()

    cond do
      present_fields > 1 ->
        add_mutual_exclusion_errors(changeset, fields, error_msg)

      present_fields == 0 and not all_fields_empty?(changeset, fields, allow_nil?) ->
        add_requirement_errors(changeset, fields, required_msg)

      true ->
        changeset
    end
  end

  @doc """
  Validates that exactly one of the specified fields is present.

  ## Options

  - `:message` - Custom error message
  - `:allow_nil` - If true, treats nil values as not present (default: false)

  ## Examples

      validate_exactly_one_field(changeset, [:card_number, :card_token])
  """
  @spec validate_exactly_one_field(Ecto.Changeset.t(), list(atom()), keyword()) :: Ecto.Changeset.t()
  def validate_exactly_one_field(changeset, fields, opts \\ []) do
    message = opts[:message] || "Exactly one of #{humanize_fields(fields)} is required"
    allow_nil? = Keyword.get(opts, :allow_nil, false)

    present_count =
      fields
      |> Enum.filter(&field_present?(changeset, &1, allow_nil?))
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
  - `:allow_nil` - If true, treats nil values as not present (default: false)

  ## Examples

      validate_any_field_present(changeset, [:email, :phone, :username])
  """
  @spec validate_any_field_present(Ecto.Changeset.t(), list(atom()), keyword()) :: Ecto.Changeset.t()
  def validate_any_field_present(changeset, fields, opts \\ []) do
    message = opts[:message] || "At least one of #{humanize_fields(fields)} is required"
    allow_nil? = Keyword.get(opts, :allow_nil, false)

    if Enum.any?(fields, &field_present?(changeset, &1, allow_nil?)) do
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

    if field_present?(changeset, if_present, false) do
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
      add_echangeset_rror(changeset, error_field, message)
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
      add_echangeset_rror(changeset, error_field, message)
    else
      changeset
    end
  end

  @doc """
  Adds a custom error to the changeset.

  ## Examples

      add_echangeset_rror(changeset, :email, "invalid format")
  """
  @spec add_echangeset_rror(Ecto.Changeset.t(), atom(), String.t()) :: Ecto.Changeset.t()
  def add_echangeset_rror(changeset, field, message) do
    add_echangeset_rror(changeset, field, message)
  end

  # Private helper functions

  defp field_present?(changeset, field, allow_nil?) do
    value = get_field(changeset, field)
    not is_nil(value) || (allow_nil? && Map.has_key?(changeset.changes, field))
  end

  defp all_fields_empty?(changeset, fields, allow_nil?) do
    Enum.all?(fields, fn field ->
      value = get_field(changeset, field)
      is_nil(value) && (!allow_nil? || !Map.has_key?(changeset.changes, field))
    end)
  end

  defp add_mutual_exclusion_errors(changeset, fields, message) do
    Enum.reduce(fields, changeset, &add_echangeset_rror(&2, &1, message))
  end

  defp add_requirement_errors(changeset, fields, message) do
    Enum.reduce(fields, changeset, fn field, cs ->
      add_echangeset_rror(cs, field, message)
    end)
  end

  defp humanize_fields(fields) do
    fields
    |> Enum.map(&Atom.to_string/1)
    |> Enum.join(", ")
  end

  defp before?(start_date, end_date, :time), do: Time.diff(start_date, end_date) < 0
  defp before?(start_date, end_date, _), do: DateTime.diff(start_date, end_date) < 0

  defp before_or_equal?(start_date, end_date, :time), do: Time.diff(start_date, end_date) <= 0
  defp before_or_equal?(start_date, end_date, _), do: DateTime.diff(start_date, end_date) <= 0
end
