defmodule Fatex.Repo do
  use Ecto.Repo,
    otp_app: :fatex_helpers,
    adapter: Ecto.Adapters.Postgres
end
