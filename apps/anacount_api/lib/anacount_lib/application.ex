defmodule AnacountAPI.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      # Start the Telemetry supervisor
      AnacountAPI.Telemetry,
      # Start the Endpoint (http/https)
      AnacountAPI.Endpoint,
      # Start the API subscription
      {Absinthe.Subscription, AnacountAPI.Endpoint}
      # Start a worker by calling: AnacountAPI.Worker.start_link(arg)
      # {AnacountAPI.Worker, arg}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: AnacountAPI.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    AnacountAPI.Endpoint.config_change(changed, removed)
    :ok
  end
end
