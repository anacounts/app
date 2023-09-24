defmodule App.MixProject do
  use Mix.Project

  def project do
    [
      app: :app,
      version: "0.1.0",
      build_path: "../../_build",
      config_path: "../../config/config.exs",
      deps_path: "../../deps",
      lockfile: "../../mix.lock",
      elixir: "~> 1.15",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps()
    ]
  end

  # Configuration for the OTP application.
  #
  # Type `mix help compile.app` for more information.
  def application do
    [
      mod: {App.Application, []},
      extra_applications: [:logger, :runtime_tools]
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Specifies your project dependencies.
  #
  # Type `mix help deps` for examples and options.
  defp deps do
    [
      {:bcrypt_elixir, "~> 3.0"},
      {:phoenix_pubsub, "~> 2.1"},
      {:ecto_sql, "~> 3.9"},
      {:postgrex, ">= 0.0.0"},
      {:cloak_ecto, "~> 1.2.0"},
      {:jason, "~> 1.4"},
      {:swoosh, "~> 1.11"},
      {:gen_smtp, "~> 1.2"},
      {:finch, "~> 0.14"},
      {:decimal, "~> 2.1"},
      {:ex_money, "~> 5.15"},
      {:ex_money_sql, "~> 1.9"},

      # Tools
      {:logger_backends, "~> 1.0"}
    ]
  end

  # Aliases are shortcuts or tasks specific to the current project.
  #
  # See the documentation for `Mix` for more info on aliases.
  defp aliases do
    [
      setup: ["deps.get", "ecto.setup"],
      "ecto.setup": ["ecto.create", "ecto.migrate", "run priv/repo/seeds.exs"],
      "ecto.reset": ["ecto.drop", "ecto.setup"],
      "ecto.gen.data_migration": [
        "ecto.gen.migration --migrations-path priv/repo/data_migrations"
      ],
      test: ["ecto.create --quiet", "ecto.migrate --quiet", "test"]
    ]
  end
end
