defmodule Fatex.FatDataSanitizerTest do
  use ExUnit.Case, async: true
  alias Fatex.FatHospital

  # Define a test module that uses our sanitizer
  defmodule TestSanitizer do
    use Fatex.FatDataSanitizer
  end

  describe "sanitize/2" do
    test "sanitizes a struct by converting to map and removing metadata" do
      hospital = %FatHospital{id: 1, name: "General", phone: "123-456-7890"}
      result = TestSanitizer.sanitize(hospital)

      assert result == %{
               id: 1,
               name: "General",
               phone: "123-456-7890",
               address: nil,
               location: nil,
               rating: nil,
               total_staff: nil
             }
    end

    test "sanitizes a list of records" do
      hospitals = [
        %FatHospital{id: 1, name: "General"},
        %FatHospital{id: 2, name: "Specialty"}
      ]

      assert [
               %{id: 1, name: "General"},
               %{id: 2, name: "Specialty"}
             ] = TestSanitizer.sanitize(hospitals)
    end

    test "handles raw maps" do
      data = %{name: "John", password: "secret"}
      assert %{name: "John"} = TestSanitizer.sanitize(data, remove: [:password])
    end

    test "masks sensitive fields" do
      data = %{email: "test@example.com", password: "secret"}
      result = TestSanitizer.sanitize(data, mask: [email: "****@****", password: "********"])

      assert result == %{
               email: "****@****",
               password: "********"
             }
    end

    test "filters fields with :only option" do
      data = %{name: "John", email: "test@example.com", age: 30}
      assert %{name: "John", age: 30} = TestSanitizer.sanitize(data, only: [:name, :age])
    end

    test "filters fields with :except option" do
      data = %{name: "John", email: "test@example.com", age: 30}
      assert %{name: "John", age: 30} = TestSanitizer.sanitize(data, except: [:email])
    end

    test "handles nested structures when deep: true" do
      data = %{
        user: %{
          name: "John",
          password: "secret",
          profile: %{bio: "Test", private: true}
        }
      }

      result = TestSanitizer.sanitize(data,
        mask: [password: "****"],
        remove: [:private],
        deep: true
      )

      assert result == %{
               user: %{
                 name: "John",
                 password: "****",
                 profile: %{bio: "Test"}
               }
             }
    end

    test "skips nested sanitization when deep: false" do
      data = %{
        user: %{
          name: "John",
          password: "secret"
        }
      }

      result = TestSanitizer.sanitize(data,
        mask: [password: "****"],
        deep: false
      )

      assert result == %{
               user: %{
                 name: "John",
                 password: "secret"  # Not masked because deep is false
               }
             }
    end

    test "handles tuples by converting to maps" do
      assert %{key: "value"} == TestSanitizer.sanitize({:key, "value"})
    end

    test "handles complex tuples with JSON encoding" do
      # Configure JSON library for test
      Application.put_env(:fatex_helpers, :json_library, Jason)

      tuple = {:complex, "data", 123, %{nested: true}}
      assert "[\"complex\",\"data\",123,{\"nested\":true}]" == TestSanitizer.sanitize(tuple)

      # Clean up
      Application.delete_env(:fatex_helpers, :json_library)
    end

    test "raises when JSON library is not configured for complex tuples" do
      Application.delete_env(:fatex_helpers, :json_library)

      assert_raise RuntimeError, fn ->
        TestSanitizer.sanitize({:complex, "tuple", 123})
      end
    end

    test "skips Ecto.Association.NotLoaded" do
      data = %{
        user: %Ecto.Association.NotLoaded{},
        name: "John"
      }

      assert %{name: "John"} == TestSanitizer.sanitize(data)
    end
  end
end
