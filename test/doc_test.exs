defmodule DocTest do
  use ExUnit.Case, async: true

  doctest Fatex.ChangesetHelper
  doctest Fatex.DateTimeHelper
  doctest Fatex.IntegerHelper
  doctest Fatex.MapHelper
  # doctest Fatex.NetworkHelper
  doctest Fatex.StringHelper
  doctest Fatex.TableHelper
  doctest Fatex.UUIDHelper
end
