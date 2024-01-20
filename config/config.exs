# This file is responsible for configuring your umbrella
# and **all applications** and their dependencies with the
# help of the Config module.
#
# Note that all applications in your umbrella share the
# same configuration and dependencies, which is why they
# all use the same configuration file. If you want different
# configurations or dependencies per app, it is best to
# move said applications out of the umbrella.
import Config

# Configure Mix tasks and generators
config :app,
  ecto_repos: [App.Repo]

# Configures the mailer
#
# By default it uses the "Local" adapter which stores the emails
# locally. You can see the emails in your browser, at "/dev/mailbox".
#
# For production, a different adapter and identity are configured
# at the `config/runtime.exs`.
config :app, App.Mailer, adapter: Swoosh.Adapters.Local

config :app_web,
  ecto_repos: [App.Repo],
  generators: [context_app: :app]

# Configures the endpoint
config :app_web, AppWeb.Endpoint,
  url: [host: "localhost"],
  render_errors: [
    formats: [html: AppWeb.ErrorHTML, json: AppWeb.ErrorJSON],
    layout: false
  ],
  pubsub_server: App.PubSub,
  live_view: [signing_salt: "F5OA2rrK"]

# Configure esbuild (the version is required)
config :esbuild,
  version: "0.19.11",
  default: [
    args:
      ~w(js/app.js --bundle --target=es2017 --outdir=../priv/static/assets --external:/fonts/* --external:/images/*),
    cd: Path.expand("../apps/app_web/assets", __DIR__),
    env: %{"NODE_PATH" => Path.expand("../deps", __DIR__)}
  ]

# Configure tailwind (the version is required)
config :tailwind,
  version: "3.4.1",
  default: [
    args: ~w(
      --config=tailwind.config.js
      --input=css/app.css
      --output=../priv/static/assets/app.css
    ),
    cd: Path.expand("../apps/app_web/assets", __DIR__)
  ]

# Configures Elixir's Logger
config :logger, :default_formatter,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# ## Internationalization
#
# Configure your application's default locale and more.

config :gettext, :default_locale, "en"
config :ex_cldr, default_backend: AppWeb.Cldr, default_locale: "en"

# ## Error reporting
#
# Configure errors to be reported to Sentry. Requires to call `plug Sentry.PlugContext`
# in the Endpoint.
# According to the Sentry documentation, the `:dsn` is "safe to keep public because they
# only allow submission of new events and related event data; they do not allow read
# access to any information".
#
# See the documentation of `:sentry` for more information.

config :sentry,
  dsn: "https://001afba5be1f4c968de015c2fc051cd9@o1240316.ingest.sentry.io/6392357",
  environment_name: Mix.env(),
  included_environments: [:prod],
  client: Sentry.FinchClient,
  enable_source_code_context: true,
  root_source_code_path: File.cwd!()

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"
