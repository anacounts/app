defmodule App.NotificationsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `App.Notifications` context.
  """

  alias App.Notifications

  @doc """
  Generate a notification.
  """
  def notification_fixture(recipients \\ []) when is_list(recipients) do
    notification_fixture(%{}, recipients)
  end

  def notification_fixture(attrs, recipients) do
    {:ok, notification} =
      attrs
      |> Enum.into(%{
        content: "some content",
        importance: :medium
      })
      |> Notifications.create_notification(recipients)

    notification
  end
end
