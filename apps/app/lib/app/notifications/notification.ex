defmodule App.Notifications.Notification do
  @moduledoc """
  A notification. Notifications may be sent to a user or a group of users.

  The `:importance` of a notification determines how it is displayed to the user.
  A notification with importance `:high` will be displayed in a prominent and intrusive
  way, a notification with importance `:medium` will be discretly signaled to the user,
  and a notification with importance `:low` will will be displayed only when the user
  explicitly requests to see all notifications.

  The `:content` is plain text that is displayed to the user.
  """

  use Ecto.Schema
  import Ecto.Changeset

  alias App.Auth.User
  alias App.Notifications.Recipient

  @type importance :: :low | :medium | :high
  @notification_importances [:low, :medium, :high]

  @type id :: integer()
  @type t :: %__MODULE__{
          id: id(),
          content: String.t(),
          importance: importance(),
          recipients: [Recipient.t()] | Ecto.Association.NotLoaded.t(),
          users: [User.t()] | Ecto.Association.NotLoaded.t(),
          inserted_at: NaiveDateTime.t(),
          updated_at: NaiveDateTime.t()
        }

  schema "notifications" do
    field :title, :string
    field :content, :string
    field :importance, Ecto.Enum, values: @notification_importances

    # Filled with the value of `read_at` of the recipient, for the current user.
    field :read_at, :naive_datetime, virtual: true

    has_many :recipients, Recipient
    many_to_many :users, User, join_through: Recipient

    timestamps()
  end

  @doc false
  def changeset(notification, attrs) do
    notification
    |> cast(attrs, [:title, :content, :importance])
    |> validate_title()
    |> validate_content()
    |> validate_importance()
  end

  defp validate_title(changeset) do
    changeset
    |> validate_required(:title)
    |> validate_length(:title, min: 1, max: 255)
  end

  defp validate_content(changeset) do
    changeset
    |> validate_required(:content)
  end

  defp validate_importance(changeset) do
    changeset
    |> validate_required(:importance)
  end
end
