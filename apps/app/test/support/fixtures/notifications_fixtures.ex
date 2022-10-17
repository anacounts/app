defmodule App.NotificationsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `App.Notifications` context.
  """

  alias App.Notifications

  def notification_attributes(attrs \\ %{}) do
    Enum.into(attrs, %{
      title: "the title",
      content: "some content",
      type: :admin_announcement
    })
  end

  def notification_fixture(attrs_or_recipients \\ [])

  def notification_fixture(recipients) when is_list(recipients) do
    notification_fixture(%{}, recipients)
  end

  def notification_fixture(attrs) do
    notification_fixture(attrs, [])
  end

  def notification_fixture(attrs, recipients) do
    {:ok, notification} =
      attrs
      |> notification_attributes()
      |> Notifications.create_notification(recipients)

    notification
  end
end
