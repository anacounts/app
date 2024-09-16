defmodule AppWeb.UserRegistrationLive do
  use AppWeb, :live_view

  alias App.Accounts
  alias App.Accounts.User

  def render(assigns) do
    ~H"""
    <.form
      for={@form}
      id="registration_form"
      class="px-4"
      phx-submit="save"
      phx-change="validate"
      phx-trigger-action={@trigger_submit}
      action={~p"/users/log_in?_action=registered"}
      method="post"
    >
      <.input
        field={@form[:email]}
        type="email"
        label={gettext("Email address")}
        class="w-full"
        required
        autocomplete="email"
      />

      <.input
        field={@form[:display_name]}
        type="text"
        label={gettext("Display name")}
        class="w-full"
        required
        autocomplete="nickname"
      />

      <.input
        field={@form[:password]}
        type="password"
        label={gettext("Password")}
        class="w-full"
        required
        autocomplete="new-password"
      />

      <div class="text-right mb-4">
        <.link navigate={~p"/users/log_in"} class="text-action">
          <%= gettext("Already have an account?") %>
        </.link>
      </div>

      <.button color={:cta} class="w-full" phx-disable-with={gettext("Creating account...")}>
        <%= gettext("Register") %>
      </.button>
    </.form>
    """
  end

  def mount(_params, _session, socket) do
    changeset = Accounts.change_user_registration(%User{})

    socket =
      socket
      |> assign(trigger_submit: false)
      |> assign(page_title: gettext("Create an account"))
      |> assign_form(changeset)

    {:ok, socket, temporary_assigns: [form: nil, page_title: nil]}
  end

  def handle_event("save", %{"user" => user_params}, socket) do
    case Accounts.register_user(user_params) do
      {:ok, user} ->
        {:ok, _} =
          Accounts.deliver_user_confirmation_instructions(
            user,
            &url(~p"/users/confirm/#{&1}")
          )

        changeset = Accounts.change_user_registration(user)
        {:noreply, socket |> assign(trigger_submit: true) |> assign_form(changeset)}

      {:error, changeset} ->
        {:noreply, socket |> assign_form(changeset)}
    end
  end

  def handle_event("validate", %{"user" => user_params}, socket) do
    changeset = Accounts.change_user_registration(%User{}, user_params)
    {:noreply, assign_form(socket, Map.put(changeset, :action, :validate))}
  end

  defp assign_form(socket, changeset) do
    form = to_form(changeset, as: "user")
    assign(socket, form: form)
  end
end
