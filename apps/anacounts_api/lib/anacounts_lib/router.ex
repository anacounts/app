defmodule AnacountsAPI.Router do
  use AnacountsAPI, :router

  pipeline :api do
    plug :accepts, ["json"]
    plug CORSPlug

    plug Anacounts.Context
  end

  scope "/api/v1" do
    pipe_through :api

    forward "/graphiql", Absinthe.Plug.GraphiQL,
      schema: AnacountsAPI.Schema,
      interface: :playground

    forward "/", Absinthe.Plug, schema: AnacountsAPI.Schema
  end

  # Enables LiveDashboard only for development
  #
  # If you want to use the LiveDashboard in production, you should put
  # it behind authentication and allow only admins to access it.
  # If your application does not have an admins-only section yet,
  # you can use Plug.BasicAuth to set up some basic authentication
  # as long as you are also using SSL (which you should anyway).
  if Mix.env() in [:dev, :test] do
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      live_dashboard "/dashboard", metrics: AnacountsAPI.Telemetry
    end
  end

  # Enables the Swoosh mailbox preview in development.
  #
  # Note that preview only shows emails that were sent by the same
  # node running the Phoenix server.
  if Mix.env() == :dev do
    scope "/dev" do
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end
end
