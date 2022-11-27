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
          book: Book.t(),
          user: User.t(),
          role: Role.t(),
          deleted_at: NaiveDateTime.t()
        }

  schema "book_members" do
    belongs_to :book, Book
    belongs_to :user, User

    field :role, Ecto.Enum, values: Role.all()
    field :deleted_at, :naive_datetime

    # Filled with the value of `:display_name` and `:email` of the linked user
    field :display_name, :string, virtual: true
    field :email, :string, virtual: true

    # Filled by the `Balance` context. Maybe be set to `{:error, reasons}` if the
    # balance cannot be computed.
    field :balance, Money.Ecto.Composite.Type, virtual: true

    timestamps()
  end

  ## Changeset

  def changeset(struct, attrs) do
    struct
    |> cast(attrs, [:role, :user_id])
    |> validate_role()
    |> validate_book_id()
    |> validate_user_id()
    |> unique_constraint([:book_id, :user_id],
      message: "user is already a member of this book",
      error_key: :user_id
    )
  end

  defp validate_role(changeset) do
    changeset
    |> validate_required(:role)
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
end
