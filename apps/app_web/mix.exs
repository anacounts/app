defmodule AppWeb.MixProject do
  use Mix.Project

  def project do
    [
      app: :app_web,
      version: "0.1.0",
      build_path: "../../_build",
      config_path: "../../config/config.exs",
      deps_path: "../../deps",
      lockfile: "../../mix.lock",
      elixir: "~> 1.15",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps(),
      gettext: [
        write_reference_comments: false,
        sort_by_msgid: :case_sensitive
      ]
    ]
  end

  # Configuration for the OTP application.
  #
  # Type `mix help compile.app` for more information.
  def application do
    [
      mod: {AppWeb.Application, []},
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
      {:phoenix, "~> 1.7.0"},
      {:phoenix_ecto, "~> 4.4"},
      {:phoenix_html, "~> 3.3"},
      {:phoenix_live_reload, "~> 1.4", only: :dev},
      {:phoenix_live_view, "~> 0.18.18"},
      {:floki, ">= 0.30.0", only: :test},
      {:phoenix_live_dashboard, "~> 0.7"},
      {:esbuild, "~> 0.7", runtime: Mix.env() == :dev},
      {:tailwind, "~> 0.2", runtime: Mix.env() == :dev},
      {:telemetry_metrics, "~> 0.6"},
      {:telemetry_poller, "~> 1.0"},
      {:gettext, "~> 0.22"},
      {:app, in_umbrella: true},
      {:sentry, "~> 8.0"},
      {:finch, "~> 0.14"},
      {:jason, "~> 1.4"},
      {:earmark, "~> 1.4"},
      {:plug_cowboy, "~> 2.6"}
    ]
  end

  # Aliases are shortcuts or tasks specific to the current project.
  #
  # See the documentation for `Mix` for more info on aliases.
  defp aliases do
    [
      setup: ["deps.get", "assets.setup", "assets.build"],
      test: ["ecto.create --quiet", "ecto.migrate --quiet", "test"],
      "assets.setup": ["tailwind.install --if-missing", "esbuild.install --if-missing"],
      "assets.build": [
        "tailwind default",
        "esbuild default",
        "sprite.generate"
      ],
      "assets.deploy": [
        "tailwind default --minify",
        "esbuild default --minify",
        "sprite.generate",
        "phx.digest"
      ],
      "sprite.generate": """
      cmd npm install svg-sprite && \
          ./node_modules/.bin/svg-sprite --dest=priv/static/assets --symbol --symbol-dest=. --symbol-sprite=sprite.svg 'assets/icons/*.svg' && \
          rm -rf node_modules/ package.json package-lock.json
      """
    ]
  end
end
