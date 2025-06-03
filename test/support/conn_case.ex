defmodule Fatex.ConnCase do
  @moduledoc false

  use ExUnit.CaseTemplate

  using do
    quote do
      import Ecto.Changeset
      import Ecto.Query
      import Fatex.Factory

      alias Fatex.Repo
    end
  end
end
