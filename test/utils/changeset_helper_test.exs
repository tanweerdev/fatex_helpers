defmodule Fatex.ChangesetHelperTest do
  use Fatex.ConnCase
  import Ecto.Changeset
  alias Fatex.ChangesetHelper, as: Helper

  describe "exclusive fields validation" do
    setup do
      %{
        schema: %Fatex.FatDoctor{
          name: nil,
          email: nil,
          phone: nil
        }
      }
    end

    test "valid when only one field is present", %{schema: schema} do
      changeset = cast(schema, %{email: "test@example.com"}, [:email, :phone])
      assert Helper.validate_exclusive_fields(changeset, [:email, :phone]).valid?
    end

    test "invalid when multiple fields are present", %{schema: schema} do
      changeset = cast(schema, %{email: "test@example.com", phone: "123456"}, [:email, :phone])
      result = Helper.validate_exclusive_fields(changeset, [:email, :phone])

      assert result.errors[:email] == {"email, phone are mutually exclusive", []}
      assert result.errors[:phone] == {"email, phone are mutually exclusive", []}
    end

    test "invalid when no fields are present", %{schema: schema} do
      changeset = cast(schema, %{}, [:email, :phone])
      result = Helper.validate_exclusive_fields(changeset, [:email, :phone])

      assert result.errors[:email] == {"At least one of email, phone is required", []}
      assert result.errors[:phone] == {"At least one of email, phone is required", []}
    end

    test "allows custom error messages", %{schema: schema} do
      changeset = cast(schema, %{email: "test@example.com", phone: "123456"}, [:email, :phone])
      result = Helper.validate_exclusive_fields(changeset, [:email, :phone],
        error_message: "Use either email or phone",
        required_message: "Contact info required"
      )

      assert result.errors[:email] == {"Use either email or phone", []}
    end

    test "handles nil values according to options", %{schema: schema} do
      # With allow_nil: false (default)
      changeset = cast(schema, %{email: nil}, [:email, :phone])
      result = Helper.validate_exclusive_fields(changeset, [:email, :phone])
      refute result.valid?

      # With allow_nil: true
      result = Helper.validate_exclusive_fields(changeset, [:email, :phone], allow_nil: true)
      assert result.valid?
    end
  end

  describe "exactly one field validation" do
    test "valid when exactly one field is present" do
      schema = %Fatex.FatDoctor{}
      changeset = cast(schema, %{email: "test@example.com"}, [:email, :phone])
      assert Helper.validate_exactly_one_field(changeset, [:email, :phone]).valid?
    end

    test "invalid when multiple fields are present" do
      schema = %Fatex.FatDoctor{}
      changeset = cast(schema, %{email: "test@example.com", phone: "123456"}, [:email, :phone])
      result = Helper.validate_exactly_one_field(changeset, [:email, :phone])

      assert result.errors[:email] == {"Exactly one of email, phone is required", []}
    end

    test "invalid when no fields are present" do
      schema = %Fatex.FatDoctor{}
      changeset = cast(schema, %{}, [:email, :phone])
      result = Helper.validate_exactly_one_field(changeset, [:email, :phone])

      assert result.errors[:email] == {"Exactly one of email, phone is required", []}
    end

    test "handles nil values according to options" do
      schema = %Fatex.FatDoctor{email: nil, phone: nil}

      # With allow_nil: false (default)
      changeset = cast(schema, %{}, [:email, :phone])
      result = Helper.validate_exactly_one_field(changeset, [:email, :phone])
      refute result.valid?

      # With allow_nil: true
      result = Helper.validate_exactly_one_field(changeset, [:email, :phone], allow_nil: true)
      assert result.valid?
    end
  end

  describe "any field present validation" do
    test "valid when at least one field is present" do
      schema = %Fatex.FatDoctor{}
      changeset = cast(schema, %{email: "test@example.com"}, [:email, :phone])
      assert Helper.validate_any_field_present(changeset, [:email, :phone]).valid?
    end

    test "invalid when no fields are present" do
      schema = %Fatex.FatDoctor{}
      changeset = cast(schema, %{}, [:email, :phone])
      result = Helper.validate_any_field_present(changeset, [:email, :phone])

      assert result.errors[:email] == {"At least one of email, phone is required", []}
    end

    test "accepts custom error message" do
      schema = %Fatex.FatDoctor{}
      changeset = cast(schema, %{}, [:email, :phone])
      result = Helper.validate_any_field_present(changeset, [:email, :phone],
        message: "Please provide contact information"
      )

      assert result.errors[:email] == {"Please provide contact information", []}
    end
  end

  describe "conditional requirement" do
    test "requires field when condition field is present" do
      schema = %Fatex.FatDoctor{}
      changeset = cast(schema, %{email: "test@example.com"}, [:email, :phone])
      result = Helper.require_field_if_present(changeset, if_present: :email, require: :phone)

      assert result.errors[:phone] == {"can't be blank", [validation: :required]}
    end

    test "doesn't require field when condition field is absent" do
      schema = %Fatex.FatDoctor{}
      changeset = cast(schema, %{}, [:email, :phone])
      result = Helper.require_field_if_present(changeset, if_present: :email, require: :phone)

      assert result.errors == []
    end

    test "accepts custom error message" do
      schema = %Fatex.FatDoctor{}
      changeset = cast(schema, %{email: "test@example.com"}, [:email, :phone])
      result = Helper.require_field_if_present(changeset,
        if_present: :email,
        require: :phone,
        message: "Phone required when email is provided"
      )

      assert result.errors[:phone] == {"Phone required when email is provided", [validation: :required]}
    end
  end

  describe "temporal validation" do
    test "validates start before end for datetimes" do
      schema = %Fatex.FatDoctor{}

      valid_changeset = cast(schema, %{
        start_time: ~U[2020-01-01 10:00:00Z],
        end_time: ~U[2020-01-01 11:00:00Z]
      }, [:start_time, :end_time])

      invalid_changeset = cast(schema, %{
        start_time: ~U[2020-01-01 12:00:00Z],
        end_time: ~U[2020-01-01 11:00:00Z]
      }, [:start_time, :end_time])

      assert Helper.validate_start_before_end(valid_changeset, :start_time, :end_time).valid?
      refute Helper.validate_start_before_end(invalid_changeset, :start_time, :end_time).valid?
    end

    test "validates start before or equal to end" do
      schema = %Fatex.FatDoctor{}

      equal_changeset = cast(schema, %{
        start_time: ~U[2020-01-01 10:00:00Z],
        end_time: ~U[2020-01-01 10:00:00Z]
      }, [:start_time, :end_time])

      assert Helper.validate_start_before_or_equal_end(equal_changeset, :start_time, :end_time).valid?
    end

    test "accepts custom error message" do
      schema = %Fatex.FatDoctor{}

      changeset = cast(schema, %{
        start_time: ~U[2020-01-01 12:00:00Z],
        end_time: ~U[2020-01-01 11:00:00Z]
      }, [:start_time, :end_time])

      result = Helper.validate_start_before_end(changeset, :start_time, :end_time,
        message: "must finish after it starts"
      )

      assert result.errors[:start_time] == {"must finish after it starts", []}
    end
  end

  describe "error handling" do
    test "adds custom error to changeset" do
      schema = %Fatex.FatDoctor{}
      changeset = cast(schema, %{}, [])
      result = Helper.add_echangeset_rror(changeset, :email, "invalid format")

      assert result.errors[:email] == {"invalid format", []}
    end
  end
end
