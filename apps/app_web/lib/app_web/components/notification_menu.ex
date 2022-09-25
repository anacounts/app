defmodule AppWeb.NotificationMenu do
  use AppWeb, :live_component

  alias App.Notifications
  alias App.Notifications.Notification

  @impl Phoenix.LiveComponent
  def update(assigns, socket) do
    notifications = Notifications.list_user_notifications(assigns.user)

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:notifications, notifications)
     |> assign(:displayed_notification, displayed_notification(notifications))}
  end

  # Notifications with high importance are displayed in a in a prominent and intrusive way.
  # We only display one notification at a time, and therefore we pick the first one which
  # is not read yet.
  defp displayed_notification(notifications) do
    Enum.find(notifications, &(is_nil(&1.read_at) and &1.importance == :high))
  end

  @impl Phoenix.LiveComponent
  def render(assigns) do
    ~H"""
    <div>
      <.modal :if={@displayed_notification} id="notification-modal" open size={:xl}>
        <%= @displayed_notification.content %>

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
      Notifications.read_notification(user, %Notification{id: notification_id})

    updated_notifications =
      Enum.map(notifications, fn n ->
        if n.id == read_notification.id, do: read_notification, else: n
      end)

    {:noreply,
     socket
     |> assign(:notifications, updated_notifications)
     |> assign(:displayed_notification, displayed_notification(updated_notifications))}
  end
end