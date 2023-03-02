defmodule AppWeb.UserConfirmationLive do
  use AppWeb, :live_view

  alias App.Accounts

  def render(assigns) do
    ~H"""
    <.form for={@form} id="confirmation_form" class="px-4" phx-submit="confirm_account">
      <.input field={@form[:token]} type="hidden" />
      <.button color={:cta} class="w-full" phx-disable-with={gettext("Confirming...")}>
        <%= gettext("Confirm your account") %>
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

  def mount(%{"token" => token}, _session, socket) do
    form = to_form(%{"token" => token}, as: "user")

    {:ok, assign(socket, form: form, page_title: gettext("Confirm your account")),
     layout: {AppWeb.Layouts, :auth}, temporary_assigns: [form: nil, page_title: nil]}
  end

  # Do not log in the user after confirmation to avoid a
  # leaked token giving the user access to the account.
  def handle_event("confirm_account", %{"user" => %{"token" => token}}, socket) do
    case Accounts.confirm_user(token) do
      {:ok, _} ->
        {:noreply,
         socket
         |> put_flash(:info, gettext("User confirmed successfully."))
         |> redirect(to: ~p"/")}

      :error ->
        # If there is a current user and the account was already confirmed,
        # then odds are that the confirmation link was already visited, either
        # by some automation or by the user themselves, so we redirect without
        # a warning message.
        case socket.assigns do
          %{current_user: %{confirmed_at: %{} = _confirmed_at}} ->
            {:noreply, redirect(socket, to: ~p"/")}

          %{} ->
            {:noreply,
             socket
             |> put_flash(:error, gettext("User confirmation link is invalid or it has expired."))
             |> redirect(to: ~p"/")}
        end
    end
  end
end
