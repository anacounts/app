defmodule AppWeb.UserSettingsLive do
  use AppWeb, :live_view

  alias App.Accounts
  alias App.Accounts.Avatars

  def render(assigns) do
    ~H"""
    <.page_header>
      <:title><%= gettext("Settings") %></:title>
    </.page_header>
    <main>
      <div class="flex items-center gap-4 mx-4 mb-4">
        <.avatar src={Avatars.avatar_url(@current_user)} alt={gettext("Your avatar")} size={:lg} />
        <div>
          <span class="font-bold"><%= @current_user.display_name %></span>
          <div><%= @current_user.email %></div>
        </div>
      </div>

      <.button color={:feature} class="mx-4" href={~p"/users/log_out"} method="delete">
        <%= gettext("Disconnect") %>
      </.button>

      <.alert :for={{type, message} <- @flash} type={type} class="mx-4">
        <%= message %>
      </.alert>

      <div class="list__item">
        <.link navigate={~p"/users/settings/balance"} class="contents">
          <div class="grow font-bold uppercase">
            <%= gettext("Balance Settings") %>
          </div>
          <.icon name="arrow-forward" />
        </.link>
      </div>
      <.accordion>
        <:item title={gettext("Change name")} open={@display_name_form.source.action}>
          <.form
            for={@display_name_form}
            id="display_name_form"
            class="mx-4"
            phx-submit="update_display_name"
            phx-change="validate_display_name"
          >
            <.input
              field={@display_name_form[:display_name]}
              type="text"
              label={gettext("New name")}
              required
              autocomplete="username"
            />

            <div>
              <.button color={:cta} phx-disable-with={gettext("Changing...")}>
                <%= gettext("Change name") %>
              </.button>
            </div>
          </.form>
        </:item>
        <:item title={gettext("Change avatar")}>
          <p class="mx-4">
            <%= gettext(
              ~s[Anacounts uses <a class="text-action" href="https://en.gravatar.com/" target="_blank" rel="noreferrer">Gravatar</a> to display user avatars.]
            )
            |> raw() %>
          </p>
          <p class="mx-4">
            <%= gettext("Gravatar is a service providing globally unique avatars")
            |> raw() %>
          </p>
          <p class="mx-4">
            <%= gettext(
              ~s[To edit your avatar, <a class="text-action" href="https://en.gravatar.com/" target="_blank" rel="noreferrer">create an account</a> and <a class="text-action" href="https://en.gravatar.com/" target="_blank" rel="noreferrer">personalize your Gravatar</a>.]
            )
            |> raw() %>
          </p>
        </:item>
        <:item title={gettext("Change email")} open={@email_form.source.action}>
          <.form
            for={@email_form}
            id="email_form"
            class="mx-4"
            phx-submit="update_email"
            phx-change="validate_email"
          >
            <.input
              field={@email_form[:email]}
              type="email"
              label={gettext("New email")}
              required
              autocomplete="username"
            />

            <.input
              field={@email_form[:current_password]}
              name="current_password"
              id="current_password_for_email"
              type="password"
              label={gettext("Password")}
              required
              autocomplete="current-password"
            />

            <div>
              <.button color={:cta} phx-disable-with={gettext("Changing...")}>
                <%= gettext("Change email") %>
              </.button>
            </div>
          </.form>
        </:item>
        <:item title={gettext("Change password")} open={@password_form.source.action}>
          <.form
            for={@password_form}
            id="password_form"
            class="mx-4"
            phx-change="validate_password"
            phx-submit="update_password"
            phx-trigger-action={@trigger_submit}
            action={~p"/users/log_in?_action=password_updated"}
            method="post"
          >
            <.input field={@password_form[:email]} type="hidden" value={@current_email} />
            <.input
              field={@password_form[:password]}
              type="password"
              label={gettext("New password")}
              required
              autocomplete="new-password"
            />
            <.input
              field={@password_form[:password_confirmation]}
              type="password"
              label={gettext("Confirm password")}
              required
              autocomplete="new-password"
            />
            <.input
              field={@password_form[:current_password]}
              name="current_password"
              id="current_password_for_password"
              type="password"
              label={gettext("Current password")}
              required
              autocomplete="current-password"
            />

            <div>
              <.button color={:cta} phx-disable-with={gettext("Changing...")}>
                <%= gettext("Change password") %>
              </.button>
            </div>
          </.form>
        </:item>
      </.accordion>
    </main>
    """
  end

  def mount(%{"token" => token}, _session, socket) do
    socket =
      case Accounts.update_user_email(socket.assigns.current_user, token) do
        :ok ->
          put_flash(socket, :info, gettext("Email changed successfully."))

        :error ->
          put_flash(socket, :error, gettext("Email change link is invalid or it has expired."))
      end

    {:ok, push_navigate(socket, to: ~p"/users/settings")}
  end

  def mount(_params, _session, socket) do
    user = socket.assigns.current_user
    display_name_changeset = Accounts.change_user_display_name(user)
    email_changeset = Accounts.change_user_email(user)
    password_changeset = Accounts.change_user_password(user)

    socket =
      assign(socket,
        page_title: gettext("Settings"),
        current_password: nil,
        display_name_form: to_form(display_name_changeset),
        email_form_current_password: nil,
        current_email: user.email,
        email_form: to_form(email_changeset),
        password_form: to_form(password_changeset),
        trigger_submit: false
      )

    {:ok, socket}
  end

  def handle_event("validate_display_name", params, socket) do
    %{"user" => user_params} = params

    display_name_form =
      socket.assigns.current_user
      |> Accounts.change_user_display_name(user_params)
      |> Map.put(:action, :validate)
      |> to_form()

    {:noreply, assign(socket, display_name_form: display_name_form)}
  end

  def handle_event("update_display_name", params, socket) do
    %{"user" => user_params} = params

    case Accounts.update_user_display_name(socket.assigns.current_user, user_params) do
      {:ok, _} ->
        {:noreply,
         socket
         |> put_flash(:info, gettext("Name updated successfully."))
         |> push_navigate(to: ~p"/users/settings")}

      {:error, changeset} ->
        {:noreply, assign(socket, display_name_form: to_form(changeset))}
    end
  end

  def handle_event("validate_email", params, socket) do
    %{"current_password" => password, "user" => user_params} = params

    email_form =
      socket.assigns.current_user
      |> Accounts.change_user_email(user_params)
      |> Map.put(:action, :validate)
      |> to_form()

    {:noreply, assign(socket, email_form: email_form, email_form_current_password: password)}
  end

  def handle_event("update_email", params, socket) do
    %{"current_password" => password, "user" => user_params} = params
    user = socket.assigns.current_user

    case Accounts.apply_user_email(user, password, user_params) do
      {:ok, applied_user} ->
        Accounts.deliver_user_update_email_instructions(
          applied_user,
          user.email,
          &url(~p"/users/settings/confirm_email/#{&1}")
        )

        info = gettext("A link to confirm your email change has been sent to the new address.")
        {:noreply, socket |> put_flash(:info, info) |> assign(email_form_current_password: nil)}

      {:error, changeset} ->
        {:noreply, assign(socket, :email_form, to_form(Map.put(changeset, :action, :insert)))}
    end
  end

  def handle_event("validate_password", params, socket) do
    %{"current_password" => password, "user" => user_params} = params

    password_form =
      socket.assigns.current_user
      |> Accounts.change_user_password(user_params)
      |> Map.put(:action, :validate)
      |> to_form()

    {:noreply, assign(socket, password_form: password_form, current_password: password)}
  end

  def handle_event("update_password", params, socket) do
    %{"current_password" => password, "user" => user_params} = params
    user = socket.assigns.current_user

    case Accounts.update_user_password(user, password, user_params) do
      {:ok, user} ->
        password_form =
          user
          |> Accounts.change_user_password(user_params)
          |> to_form()

        {:noreply, assign(socket, trigger_submit: true, password_form: password_form)}

      {:error, changeset} ->
        {:noreply, assign(socket, password_form: to_form(changeset))}
    end
  end
end
