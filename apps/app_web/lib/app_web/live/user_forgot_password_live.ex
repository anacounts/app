defmodule AppWeb.UserForgotPasswordLive do
  use AppWeb, :live_view

  alias App.Accounts

  def render(assigns) do
    ~H"""
    <p class="mx-4 mb-4">
      <%= gettext(
        "Enter your user account's email address and we will send you a password reset link."
      ) %>
    </p>

    <.form for={@form} id="reset_password_form" class="mx-4" phx-submit="send_email">
      <.input
        field={@form[:email]}
        type="email"
        label={gettext("Email address")}
        class="w-full"
        autocomplete="email"
        required
      />

      <.button color={:cta} class="w-full">
        <%= gettext("Send password reset instructions") %>
      </.button>
    </.form>

    <div class="mt-8
                border-t border-gray-50
                text-center
                text-gray-50 font-bold">
      <span class="relative bottom-3 p-3 bg-white">
        <%= gettext("Or continue to") %>
      </span>
    </div>

    <div class="flex justify-between">
      <.link navigate={~p"/users/log_in"} class="text-action">
        <%= gettext("Sign in to your account") %>
      </.link>
      <.link navigate={~p"/users/register"} class="text-action">
        <%= gettext("Create an account") %>
      </.link>
    </div>
    """
  end

  def mount(_params, _session, socket) do
    {:ok,
     assign(socket, form: to_form(%{}, as: "user"), page_title: gettext("Forgot your password?")),
     layout: {AppWeb.Layouts, :auth}, temporary_assigns: [page_title: nil]}
  end

  def handle_event("send_email", %{"user" => %{"email" => email}}, socket) do
    if user = Accounts.get_user_by_email(email) do
      Accounts.deliver_user_reset_password_instructions(
        user,
        &url(~p"/users/reset_password/#{&1}")
      )
    end

    info =
      "If your email is in our system, you will receive instructions to reset your password shortly."

    {:noreply,
     socket
     |> put_flash(:info, info)
     |> redirect(to: ~p"/")}
  end
end
