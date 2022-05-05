defmodule Anacounts.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl Application
  def start(_type, _args) do
    children = [
      # Start the Ecto repository
      Anacounts.Repo,
      # Start the PubSub system
      {Phoenix.PubSub, name: Anacounts.PubSub}
      # Start a worker by calling: Anacounts.Worker.start_link(arg)
      # {Anacounts.Worker, arg}
    ]

    Supervisor.start_link(children, strategy: :one_for_one, name: Anacounts.Supervisor)
  end
end
