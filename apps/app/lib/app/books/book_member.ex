defmodule App.Books.BookMember do
  @moduledoc """
  The link between a book and a user.
  It contains the role of the user for this particular book.
  """
  use Ecto.Schema
  import Ecto.Changeset

  alias App.Auth.User
  alias App.Books.Book
  alias App.Books.Role

  @type id :: integer()

  @type t :: %__MODULE__{
          id: id(),
          book_id: Book.id(),
          book: Book.t(),
          user_id: User.id() | nil,
          user: User.t() | nil,
          role: Role.t(),
          deleted_at: NaiveDateTime.t(),
          nickname: String.t(),
          display_name: String.t() | nil,
          email: String.t() | nil,
          balance: Money.t() | {:error, reasons :: [String.t()]} | nil
        }

  schema "book_members" do
    belongs_to :book, Book
    belongs_to :user, User

    field :role, Ecto.Enum, values: Role.all()
    field :deleted_at, :naive_datetime

    # When the member is not linked to a user, the display name falls back to the book
    # member's `:nickname`, set at creation
    field :nickname, :string

    # Filled with the user `:display_name` if there is one, otherwise `:nickname`
    field :display_name, :string, virtual: true
    # Filled with the user `:email` if there is one
    field :email, :string, virtual: true

    # Filled by the `Balance` context. Maybe be set to `{:error, reasons}` if the
    # balance cannot be computed.
    field :balance, Money.Ecto.Composite.Type, virtual: true

    timestamps()
  end

  ## Changeset

  def changeset(struct, attrs) do
    struct
    |> cast(attrs, [:user_id, :role, :nickname])
    |> validate_book_id()
    |> validate_user_id()
    |> validate_role()
    |> validate_nickname()
    |> unique_constraint([:book_id, :user_id],
      message: "user is already a member of this book",
      error_key: :user_id
    )
  end

  defp validate_book_id(changeset) do
    changeset
    |> validate_required(:book_id)
    |> foreign_key_constraint(:book_id)
  end

  defp validate_user_id(changeset) do
    changeset
    |> foreign_key_constraint(:user_id)
  end

  defp validate_role(changeset) do
    changeset
    |> validate_required(:role)
  end

  defp validate_nickname(changeset) do
    changeset
    |> validate_required(:nickname)
    |> validate_length(:nickname, min: 1, max: 255)
  end
end
