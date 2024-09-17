defmodule AppWeb.Router do
  # There is no reason to worry about module dependencies
  # in the router, disable the check here.
  # credo:disable-for-this-file Credo.Check.Refactor.ModuleDependencies

  use AppWeb, :router

  import AppWeb.UserAuth

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session

    plug Cldr.Plug.PutLocale,
      apps: [:cldr, :gettext],
      from: [:accept_language],
      gettext: AppWeb.Gettext,
      cldr: AppWeb.Cldr

    plug Cldr.Plug.PutSession

    plug :fetch_live_flash
    plug :put_root_layout, {AppWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :fetch_current_user
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
      on_mount: [{AppWeb.UserAuth, :redirect_if_user_is_authenticated}],
      layout: {AppWeb.Layouts, :auth} do
      live "/users/register", UserRegistrationLive, :new
      live "/users/log_in", UserLoginLive, :new
      live "/users/reset_password", UserForgotPasswordLive, :new
      live "/users/reset_password/:token", UserResetPasswordLive, :edit
    end

    post "/users/log_in", UserSessionController, :create
  end

  scope "/", AppWeb do
    pipe_through [:browser, :require_authenticated_user]

    live_session :user_settings,
      on_mount: [{AppWeb.UserAuth, :ensure_authenticated}] do
      live "/users/settings", UserSettingsLive, :edit
      live "/users/settings/email", UserSettingsEmailLive, :edit
      live "/users/settings/email/confirm/:token", UserSettingsEmailLive, :confirm_email
      live "/users/settings/avatar", UserSettingsAvatarLive, :edit
      live "/users/settings/password", UserSettingsPasswordLive, :edit

      live "/users/settings/balance", BalanceConfigLive, :edit
    end

    live_session :user_confirmation,
      on_mount: [{AppWeb.UserAuth, :ensure_authenticated}],
      layout: {AppWeb.Layouts, :auth} do
      live "/users/confirm", UserConfirmationInstructionsLive, :new
    end

    get "/users/confirm/:token", UserConfirmationController, :update
  end

  scope "/", AppWeb do
    pipe_through [:browser]

    delete "/users/log_out", UserSessionController, :delete
  end

  ## Books routes

  scope "/", AppWeb do
    pipe_through [:browser, :require_authenticated_user]

    live_session :books, on_mount: [{AppWeb.UserAuth, :ensure_authenticated}] do
      live "/books", BooksLive, :index
      live "/books/new", BookFormLive, :new
      live "/books/:book_id", BookLive, :show
      live "/books/:book_id/edit", BookFormLive, :edit

      live "/books/:book_id/invite", BookInvitationsLive, :show
      live "/books/:book_id/members", BookMembersLive, :index
      live "/books/:book_id/members/new", BookMemberFormLive, :new
      live "/books/:book_id/members/:book_member_id", BookMemberLive, :show
      live "/books/:book_id/members/:book_member_id/edit", BookMemberFormLive, :edit
      live "/books/:book_id/transfers", MoneyTransfersLive, :index
      live "/books/:book_id/transfers/new", MoneyTransferFormLive, :new
      live "/books/:book_id/transfers/:money_transfer_id/edit", MoneyTransferFormLive, :edit
      live "/books/:book_id/balance", BookBalanceLive, :show
    end

    get "/invitations/:token", BookInvitationController, :edit
    put "/invitations/:token", BookInvitationController, :update
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
    import PhoenixStorybook.Router

    scope "/" do
      storybook_assets()
    end

    scope "/" do
      pipe_through :browser

      live_storybook("/storybook", backend_module: AppWeb.Storybook)
    end

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: AppWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end
end
