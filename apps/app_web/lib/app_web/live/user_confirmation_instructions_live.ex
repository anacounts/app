defmodule AppWeb.UserConfirmationInstructionsLive do
  use AppWeb, :live_view

  alias App.Accounts

  def render(assigns) do
    ~H"""
    <.form for={@form} id="resend_confirmation_form" class="px-4" phx-submit="send_instructions">
      <.input field={@form[:email]} type="email" label="Email" required autocomplete="username" />

      <.button color={:cta} class="w-full" phx-disable-with={gettext("Sending...")}>
        <%= gettext("Resend confirmation instructions") %>
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
      <.link href={~p"/users/log_in"} class="text-action">
        <%= gettext("Sign in to your account") %>
      </.link>
      <.link href={~p"/users/register"} class="text-action">
        <%= gettext("Create an account") %>
      </.link>
    </div>
    """
  end

  def mount(_params, _session, socket) do
    {:ok,
     assign(socket,
       form: to_form(%{}, as: "user"),
       page_title: gettext("Resend confirmation instructions")
     ), layout: {AppWeb.Layouts, :auth}, temporary_assigns: [page_title: nil]}
  end

  def handle_event("send_instructions", %{"user" => %{"email" => email}}, socket) do
    if user = Accounts.get_user_by_email(email) do
      Accounts.deliver_user_confirmation_instructions(
        user,
        &url(~p"/users/confirm/#{&1}")
      )
    end

    info =
      gettext(
        "If your email is in our system and it has not been confirmed yet, you will receive an email with instructions shortly."
      )

    {:noreply,
     socket
     |> put_flash(:info, info)
     |> redirect(to: ~p"/")}
  end
end
