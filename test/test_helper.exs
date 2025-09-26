ExUnit.start(exclude: :skip)

{:ok, _} = Application.ensure_all_started(:fatex_helpers)
{:ok, _} = Fatex.Repo.start_link()
Ecto.Adapters.SQL.Sandbox.mode(Fatex.Repo, :auto)
