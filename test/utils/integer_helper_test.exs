defmodule Utils.IntegerTest do
  use Fatex.ConnCase
  alias Fatex.IntegerHelper

  test "parse integer/integer string with returning tuple" do
    assert IntegerHelper.parse(12) == {:ok, 12}
    assert IntegerHelper.parse("12r") == {:ok, 12}
    assert IntegerHelper.parse("rrrr") == {:error, nil}
  end

  test "parse integer/integer string" do
    assert IntegerHelper.parse!(14) == 14
    assert IntegerHelper.parse!("14rtyt") == 14
    assert IntegerHelper.parse!("rrrr") == nil
  end
end
