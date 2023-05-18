defmodule AppWeb.Router do
  use AppWeb, :router

  import AppWeb.UserAuth

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, {AppWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :fetch_current_user
    plug AppWeb.Locale
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", AppWeb do
    pipe_through :browser

    get "/", PageController, :index
  end

  ## Authentication routes

  scope "/", AppWeb do
    pipe_through [:browser, :redirect_if_user_is_authenticated]

    live_session :redirect_if_user_is_authenticated,
      on_mount: [{AppWeb.UserAuth, :redirect_if_user_is_authenticated}] do
      live "/users/register", UserRegistrationLive, :new
      live "/users/log_in", UserLoginLive, :new
      live "/users/reset_password", UserForgotPasswordLive, :new
      live "/users/reset_password/:token", UserResetPasswordLive, :edit
    end

    post "/users/log_in", UserSessionController, :create
  end

  scope "/", AppWeb do
    pipe_through [:browser, :require_authenticated_user]

    live_session :require_authenticated_user,
      on_mount: [{AppWeb.UserAuth, :ensure_authenticated}] do
      live "/users/settings", UserSettingsLive, :edit
      live "/users/settings/confirm_email/:token", UserSettingsLive, :confirm_email

      live "/users/settings/balance", BalanceConfigLive.Edit, :edit
    end
  end

  scope "/", AppWeb do
    pipe_through [:browser]

    delete "/users/log_out", UserSessionController, :delete

    live_session :current_user,
      on_mount: [{AppWeb.UserAuth, :mount_current_user}] do
      live "/users/confirm/:token", UserConfirmationLive, :edit
      live "/users/confirm", UserConfirmationInstructionsLive, :new
    end
  end

  ## Books routes

  scope "/", AppWeb do
    pipe_through [:browser, :require_authenticated_user]

    live_session :books, on_mount: [{AppWeb.UserAuth, :ensure_authenticated}] do
      live "/books", BookLive.Index, :index
      live "/books/new", BookLive.Form, :new
      live "/books/:book_id/edit", BookLive.Form, :edit

      live "/books/:book_id/invite", InvitationLive.Index, :index
      live "/books/:book_id/members", BookMemberLive.Index, :index
      live "/books/:book_id/transfers", MoneyTransferLive.Index, :index
      live "/books/:book_id/transfers/new", MoneyTransferLive.Form, :new
      live "/books/:book_id/transfers/:money_transfer_id/edit", MoneyTransferLive.Form, :edit
      live "/books/:book_id/balance", BookBalanceLive, :show
    end

    resources "/invitation", BookInvitationController, param: "token", only: [:edit, :update]
  end

  ## Metrics routes

  scope "/", AppWeb do
    get "/metrics/health_check", MetricsController, :health_check
  end

  # Other scopes may use custom stacks.
  # scope "/api", AppWeb do
  #   pipe_through :api
  # end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:app_web, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: AppWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end
end
