defmodule App.Notifications.Recipient do
  @moduledoc """
  The recipient of a notification. Stores the read time of a notification.
  A notification that has not been read by the user has a `nil` `:read_at`.
  """

  use Ecto.Schema
  import Ecto.Changeset

  alias App.Auth.User
  alias App.Notifications.Notification

  @type id :: integer()
  @type t :: %__MODULE__{
          id: id(),
          notification_id: Notification.id(),
          notification: Notification.t() | Ecto.Association.NotLoaded.t(),
          user_id: User.id(),
          user: User.t() | Ecto.Association.NotLoaded.t(),
          read_at: NaiveDateTime.t() | nil,
          inserted_at: NaiveDateTime.t(),
          updated_at: NaiveDateTime.t()
        }

  schema "notification_recipients" do
    field :read_at, :naive_datetime

    belongs_to :notification, Notification
    belongs_to :user, User

    timestamps()
  end

  @doc false
  def changeset(recipient, attrs) do
    recipient
    |> cast(attrs, [:read_at, :user_id, :notification_id])
    |> validate_notification_id()
    |> validate_user_id()
  end

  defp validate_notification_id(changeset) do
    changeset
    |> validate_required(:notification_id)
    |> foreign_key_constraint(:notification_id)
  end

  defp validate_user_id(changeset) do
    changeset
    |> validate_required(:user_id)
    |> foreign_key_constraint(:user_id)
  end
end
