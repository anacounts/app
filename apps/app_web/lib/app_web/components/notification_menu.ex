defmodule AppWeb.NotificationMenu do
  @moduledoc """
  A component that renders the main notification menu.

  The component is the main display point for notifications: give it a `:user`, it will
  display their highly important notifications in a modal, but also mark them as read,
  when they close it.

  ## Attributes

  - `:user` - the user to render the notifications for.

  ## Examples

      <.live_component module={AppWeb.NotificationMenu} id="notification-menu />

  """
  use AppWeb, :live_component

  alias App.Notifications

  @impl Phoenix.LiveComponent
  def update(assigns, socket) do
    notifications = Notifications.list_notifications_of_user(assigns.user)

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:notifications, notifications)
     |> assign(:displayed_notification, displayed_notification(notifications))}
  end

  @impl Phoenix.LiveComponent
  def render(assigns) do
    ~H"""
    <div>
      <.modal
        :if={@displayed_notification}
        id="notification-modal"
        open
        size={:xl}
        dismiss={not Notifications.urgent?(@displayed_notification)}
      >
        <:header>
          <.icon name={Notifications.icon(@displayed_notification)} />
          <%= @displayed_notification.title %>
        </:header>

        <.markdown content={@displayed_notification.content} />

        <:footer>
          <.button
            color="feature"
            phx-click="mark_as_read"
            phx-target={@myself}
            phx-value-id={@displayed_notification.id}
          >
            <%= gettext("Close") %>
          </.button>
        </:footer>
      </.modal>
    </div>
    """
  end

  @impl Phoenix.LiveComponent
  def handle_event("mark_as_read", %{"id" => notification_id}, socket) do
    %{user: user, notifications: notifications} = socket.assigns

    {:ok, read_notification} =
      Notifications.read_notification(user, Notifications.get_notification!(notification_id))

    updated_notifications =
      Enum.map(notifications, fn n ->
        if n.id == read_notification.id, do: read_notification, else: n
      end)

    {:noreply,
     socket
     |> assign(:notifications, updated_notifications)
     |> assign(:displayed_notification, displayed_notification(updated_notifications))}
  end

  # Notifications which are urgent are displayed in a in a prominent and intrusive way.
  # We only display one notification at a time, and therefore we pick the first one which
  # is not read yet.
  defp displayed_notification(notifications) do
    Enum.find(notifications, &(not Notifications.read?(&1) and Notifications.urgent?(&1)))
  end
end
