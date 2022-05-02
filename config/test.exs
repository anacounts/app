import Config

# Configure your database
#
# The MIX_TEST_PARTITION environment variable can be used
# to provide built-in test partitioning in CI environment.
# Run `mix help test` for more information.
config :anacount, Anacount.Repo,
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  database: "anacount_test#{System.get_env("MIX_TEST_PARTITION")}",
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: 10

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :anacount_web, AnacountWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "GHLDzAtB0iRfyK+gf+IQv69IFSZXgXQoYGyektl5fk90x/dxOW2WZ2OhH3XYvpK3",
  server: false

# Print only warnings and errors during test
config :logger, level: :warn

# In test we don't send emails.
config :anacount, Anacount.Mailer, adapter: Swoosh.Adapters.Test

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime
