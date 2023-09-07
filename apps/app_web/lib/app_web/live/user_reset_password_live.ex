defmodule AppWeb.UserResetPasswordLive do
  use AppWeb, :live_view

  alias App.Accounts

  def render(assigns) do
    ~H"""
    <.form
      for={@form}
      id="reset_password_form"
      class="px-4"
      phx-submit="reset_password"
      phx-change="validate"
    >
      <p><%= gettext("Please enter a new password for your account") %></p>
      <p class="mb-4 font-bold"><%= @user.email %></p>

      <.input
        field={@form[:password]}
        type="password"
        label={gettext("New password")}
        class="w-full"
        required
        autocomplete="new-password"
      />

      <.input
        field={@form[:password_confirmation]}
        type="password"
        label={gettext("Confirm new password")}
        class="w-full"
        required
        autocomplete="new-password"
      />

      <div>
        <.button color={:cta} class="w-full" phx-disable-with={gettext("Resetting...")}>
          <%= gettext("Reset password") %>
        </.button>
      </div>
    </.form>

    <div class="mt-8
                border-t border-gray-50
                text-center
                text-gray-50 font-bold">
      <span class="relative bottom-3 p-3 bg-white">
        <%= gettext("Or continue to") %>
      </span>
    </div>

    <.link navigate={~p"/users/log_in"} class="text-action">
      <%= gettext("Sign in to your account") %>
    </.link>
    """
  end

  def mount(params, _session, socket) do
    socket = assign_user_and_token(socket, params)

    form_source =
      case socket.assigns do
        %{user: user} ->
          Accounts.change_user_password(user)

        _ ->
          %{}
      end

    {:ok,
     socket |> assign(page_title: gettext("Reset your password")) |> assign_form(form_source),
     layout: {AppWeb.Layouts, :auth}, temporary_assigns: [form: nil, page_title: nil]}
  end

  # Do not log in the user after reset password to avoid a
  # leaked token giving the user access to the account.
  def handle_event("reset_password", %{"user" => user_params}, socket) do
    case Accounts.reset_user_password(socket.assigns.user, user_params) do
      {:ok, _} ->
        {:noreply,
         socket
         |> put_flash(:info, gettext("Password reset successfully."))
         |> redirect(to: ~p"/users/log_in")}

      {:error, changeset} ->
        {:noreply, assign_form(socket, Map.put(changeset, :action, :insert))}
    end
  end

  def handle_event("validate", %{"user" => user_params}, socket) do
    changeset = Accounts.change_user_password(socket.assigns.user, user_params)
    {:noreply, assign_form(socket, Map.put(changeset, :action, :validate))}
  end

  defp assign_user_and_token(socket, %{"token" => token}) do
    if user = Accounts.get_user_by_reset_password_token(token) do
      assign(socket, user: user, token: token)
    else
      socket
      |> put_flash(:error, gettext("Reset password link is invalid or it has expired."))
      |> redirect(to: ~p"/")
    end
  end

  defp assign_form(socket, source) do
    assign(socket, :form, to_form(source, as: "user"))
  end
end
