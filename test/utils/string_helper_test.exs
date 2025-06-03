defmodule Utils.StringTest do
  use Fatex.ConnCase
  import Fatex.StringHelper

  test "Generate random strings of different lengths" do
    assert String.length(random(9)) == 9
    assert String.length(random(12)) == 12
    assert String.length(random(25)) == 25
    assert String.length(random()) == 8
  end
end
