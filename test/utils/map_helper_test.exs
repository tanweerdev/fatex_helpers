defmodule Utils.MapTest do
  use Fatex.ConnCase
  alias Fatex.MapHelper

  test "has all keys" do
    map = %{name: "John", phone: "123456", address: "123 main bullavord"}
    keys = [:name, :phone]
    assert MapHelper.has_all_keys?(map, keys) == true

    keys = [:name, :designation]
    assert MapHelper.has_all_keys?(map, keys) == false
  end

  test "has all values equal to" do
    map = %{name: "John", phone: "123456", address: "123 main bullavord"}
    keys = [:name]
    equal_to = "John"
    assert MapHelper.has_all_val_equal_to?(map, keys, equal_to) == true

    keys = [:name, :designation]
    equal_to = "John"

    assert MapHelper.has_all_val_equal_to?(map, keys, equal_to) == false
  end

  test "has any keys" do
    map = %{name: "John", phone: "123456", address: "123 main bullavord"}
    keys = [:name]
    assert MapHelper.has_any_of_keys?(map, keys) == true

    keys = [:work]

    assert MapHelper.has_any_of_keys?(map, keys) == false
  end

  test "deep merge" do
    map_1 = %{name: "John", phone: "123456", address: "123 main bullavord"}
    map_2 = %{last_name: "Doe", designation: "engineer", home_address: "123 main bullavord"}

    assert MapHelper.deep_merge(map_1, map_2) ==
             %{
               address: "123 main bullavord",
               designation: "engineer",
               home_address: "123 main bullavord",
               last_name: "Doe",
               name: "John",
               phone: "123456"
             }
  end
end
