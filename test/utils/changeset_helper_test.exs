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

      result =
        Helper.validate_exclusive_fields(changeset, [:email, :phone],
          error_message: "Use either email or phone",
          required_message: "Contact info required"
        )

      assert result.errors[:email] == {"Use either email or phone", []}
    end

    test "handles treat_values_absent option" do
      # Test treat_values_absent - empty strings treated as absent
      changeset = cast(%Fatex.FatDoctor{}, %{email: "test@example.com", phone: ""}, [:email, :phone])
      result = Helper.validate_exclusive_fields(changeset, [:email, :phone], treat_values_absent: [""])
      # Should pass because phone is treated as absent
      assert result.valid?

      # Test treat_values_absent with "0" string
      changeset2 = cast(%Fatex.FatDoctor{}, %{email: "valid@email.com", phone: "0"}, [:email, :phone])
      result = Helper.validate_exclusive_fields(changeset2, [:email, :phone], treat_values_absent: ["0"])
      # Should pass because only email is present, phone ("0") is absent
      assert result.valid?

      # Test both options together with different values
      changeset3 = cast(%Fatex.FatDoctor{}, %{email: "PRESENT", phone: "0"}, [:email, :phone])

      result =
        Helper.validate_exclusive_fields(changeset3, [:email, :phone],
          treat_values_present: ["PRESENT"],
          treat_values_absent: ["0"]
        )

      # Should pass because email ("PRESENT") is treated as present, phone ("0") is absent
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

    test "handles treat_values_absent option" do
      # Test treat_values_absent with empty strings
      changeset = cast(%Fatex.FatDoctor{}, %{email: "test@example.com", phone: ""}, [:email, :phone])
      result = Helper.validate_exactly_one_field(changeset, [:email, :phone], treat_values_absent: [""])
      # Should pass because only email is present (phone treated as absent)
      assert result.valid?

      # Test treat_values_absent with "0" string
      changeset2 = cast(%Fatex.FatDoctor{}, %{email: "valid@email.com", phone: "0"}, [:email, :phone])
      result = Helper.validate_exactly_one_field(changeset2, [:email, :phone], treat_values_absent: ["0"])
      # Should pass because only email is present, phone ("0") is absent
      assert result.valid?

      # Test both options together with different values
      changeset3 = cast(%Fatex.FatDoctor{}, %{email: "PRESENT", phone: "0"}, [:email, :phone])

      result =
        Helper.validate_exactly_one_field(changeset3, [:email, :phone],
          treat_values_present: ["PRESENT"],
          treat_values_absent: ["0"]
        )

      # Should pass because email ("PRESENT") is treated as present, phone ("0") is absent
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

      result =
        Helper.validate_any_field_present(changeset, [:email, :phone],
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

      result =
        Helper.require_field_if_present(changeset,
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

      valid_changeset =
        cast(
          schema,
          %{
            start_date: ~U[2020-01-01 10:00:00Z],
            end_date: ~U[2020-01-01 11:00:00Z]
          },
          [:start_date, :end_date]
        )

      invalid_changeset =
        cast(
          schema,
          %{
            start_date: ~U[2020-01-01 12:00:00Z],
            end_date: ~U[2020-01-01 11:00:00Z]
          },
          [:start_date, :end_date]
        )

      assert Helper.validate_start_before_end(valid_changeset, :start_date, :end_date).valid?
      refute Helper.validate_start_before_end(invalid_changeset, :start_date, :end_date).valid?
    end

    test "validates start before or equal to end" do
      schema = %Fatex.FatDoctor{}

      equal_changeset =
        cast(
          schema,
          %{
            start_date: ~U[2020-01-01 10:00:00Z],
            end_date: ~U[2020-01-01 10:00:00Z]
          },
          [:start_date, :end_date]
        )

      assert Helper.validate_start_before_or_equal_end(equal_changeset, :start_date, :end_date).valid?
    end

    test "accepts custom error message" do
      schema = %Fatex.FatDoctor{}

      changeset =
        cast(
          schema,
          %{
            start_date: ~U[2020-01-01 12:00:00Z],
            end_date: ~U[2020-01-01 11:00:00Z]
          },
          [:start_date, :end_date]
        )

      result =
        Helper.validate_start_before_end(changeset, :start_date, :end_date,
          message: "must finish after it starts"
        )

      assert result.errors[:start_date] == {"must finish after it starts", []}
    end
  end

  describe "error handling" do
    test "adds custom error to changeset" do
      schema = %Fatex.FatDoctor{}
      changeset = cast(schema, %{}, [])
      result = Helper.add_changeset_error(changeset, :email, "invalid format")

      assert result.errors[:email] == {"invalid format", []}
    end
  end
end
