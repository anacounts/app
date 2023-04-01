defmodule AppWeb.UserLoginLive do
  use AppWeb, :live_view

  def render(assigns) do
    ~H"""
    <.form for={@form} id="login_form" class="px-4" action={~p"/users/log_in"} phx-update="ignore">
      <.input
        field={@form[:email]}
        type="email"
        label={gettext("Email address")}
        class="w-full"
        required
        autocomplete="email"
      />

      <.input
        field={@form[:password]}
        type="password"
        label={gettext("Password")}
        class="w-full"
        required
        autocomplete="current-password"
      />

      <div class="flex justify-between">
        <.input field={@form[:remember_me]} type="checkbox" label={gettext("Keep me logged in")} />

        <.link navigate={~p"/users/reset_password"} class="text-action">
          <%= gettext("Forgot your password?") %>
        </.link>
      </div>

      <.button color={:cta} class="w-full" phx-disable-with={gettext("Signing in...")}>
        <%= gettext("Sign in") %>
      </.button>
    </.form>

    <div class="mt-8
                border-t border-gray-50
                text-center
                text-gray-50 font-bold">
      <span class="relative bottom-3 p-3 bg-white">
        <%= gettext("Don't have an account?") %>
      </span>
    </div>

    <.button color={:feature} class="block w-fit mx-auto" navigate={~p"/users/register"}>
      <.icon name="mail" />
      <%= gettext("Create one here") %>
    </.button>
    """
  end

  def mount(_params, _session, socket) do
    email = live_flash(socket.assigns.flash, :email)
    form = to_form(%{"email" => email}, as: "user")

    {:ok, assign(socket, form: form, page_title: gettext("Sign in to your account")),
     temporary_assigns: [form: form, page_title: nil], layout: {AppWeb.Layouts, :auth}}
  end
end
