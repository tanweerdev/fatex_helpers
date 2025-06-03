import Config

config :fatex_helpers,
  ecto_repos: [Fatex.Repo]

config :fatex_helpers, Fatex.Repo,
  username: "postgres",
  password: "postgres",
  database: "fatex_helpers_test",
  hostname: "localhost",
  pool: Ecto.Adapters.SQL.Sandbox,
  log: false
