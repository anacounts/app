defmodule App.Notifications.Notification do
  @moduledoc """
  A notification. Notifications may be sent to a user or a group of users.

  The `:type` of a notification specifies the reason why it was created.
  It is be used to determine its urgency (see `App.Notifications.urgent?/1`),
  the icon that should be displayed alongside, and can be used for more.

  The `:content` is markdown text that is rendered and displayed to the user.
  """

  use Ecto.Schema
  import Ecto.Changeset

  alias App.Notifications.Recipient

  @type type :: :admin_announcement
  @notification_types [:admin_announcement]

  @type id :: integer()
  @type t :: %__MODULE__{
          id: id(),
          content: String.t(),
          type: type(),
          recipients: [Recipient.t()] | Ecto.Association.NotLoaded.t(),
          inserted_at: NaiveDateTime.t(),
          updated_at: NaiveDateTime.t()
        }

  schema "notifications" do
    field :title, :string
    field :content, :string
    field :type, Ecto.Enum, values: @notification_types

    # Filled with the value of `read_at` of the recipient, for the current user.
    field :read_at, :naive_datetime, virtual: true

    has_many :recipients, Recipient

    timestamps()
  end

  @doc false
  def changeset(notification, attrs) do
    notification
    |> cast(attrs, [:title, :content, :type])
    |> validate_title()
    |> validate_content()
    |> validate_type()
  end

  defp validate_title(changeset) do
    changeset
    |> validate_required(:title)
    |> validate_length(:title, min: 1, max: 80)
  end

  defp validate_content(changeset) do
    changeset
    |> validate_required(:content)
  end

  defp validate_type(changeset) do
    changeset
    |> validate_required(:type)
  end
end
