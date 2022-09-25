defmodule App.NotificationsTest do
  use App.DataCase

  import App.AuthFixtures
  import App.NotificationsFixtures

  alias App.Notifications
  alias App.Notifications.Notification
  alias App.Notifications.Recipient

  @invalid_attrs %{content: nil, importance: :none}

  describe "list_user_notifications/1" do
    test "returns all user notifications" do
      user = user_fixture()
      notification1 = notification_fixture([user])
      notification2 = notification_fixture(%{importance: :high}, [user])

      _not_for_user = notification_fixture()

      assert Notifications.list_user_notifications(user) == [notification1, notification2]
    end
  end

  describe "get_notification!/1" do
    test "returns the notification with given id" do
      notification = notification_fixture()
      assert Notifications.get_notification!(notification.id) == notification
    end

    test "raises if notification does not exist" do
      assert_raise Ecto.NoResultsError, fn ->
        Notifications.get_notification!(-1)
      end
    end
  end

  describe "create_notification/2" do
    test "with valid data creates a notification" do
      user1 = user_fixture()
      user2 = user_fixture()

      valid_attrs = %{content: "some content", importance: :high}

      assert {:ok, %Notification{} = notification} =
               Notifications.create_notification(valid_attrs, [user1, user2])

      assert notification.content == "some content"
      assert notification.importance == :high
    end

    test "with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Notifications.create_notification(@invalid_attrs, [])
    end

    test "does not send twice to the same user" do
      user = user_fixture()

      assert {:ok, notification} =
               Notifications.create_notification(%{content: "some content", importance: :high}, [
                 user,
                 user
               ])

      assert %Recipient{} = Notifications.get_recipient!(notification.id, user.id)
    end
  end

  describe "read_notification/2" do
    test "reads a notification" do
      user = user_fixture()
      notification = notification_fixture([user])

      assert {:ok, %Notification{}} = Notifications.read_notification(user, notification)
      assert Notifications.read?(user, notification)
    end

    test "raises if the notification was not sent to the user" do
      notification = notification_fixture()
      user = user_fixture()

      assert_raise Ecto.NoResultsError, fn ->
        Notifications.read_notification(user, notification)
      end
    end
  end

  describe "read?/2" do
    test "returns true if the notification was read by the user" do
      user = user_fixture()
      notification = notification_fixture([user])

      refute Notifications.read?(user, notification)

      Notifications.read_notification(user, notification)

      assert Notifications.read?(user, notification)
    end

    test "raises if the notification was not sent to the user" do
      notification = notification_fixture()
      user = user_fixture()

      assert_raise Ecto.NoResultsError, fn ->
        Notifications.read?(user, notification)
      end
    end
  end

  describe "delete_notification/1" do
    test "deletes the notification" do
      notification = notification_fixture()
      assert {:ok, %Notification{}} = Notifications.delete_notification(notification)

      assert_raise Ecto.NoResultsError, fn ->
        Notifications.get_notification!(notification.id)
      end
    end
  end

  describe "change_notification/1" do
    test "returns a notification changeset" do
      notification = notification_fixture()
      assert %Ecto.Changeset{} = Notifications.change_notification(notification)
    end
  end
end
