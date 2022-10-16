defmodule App.Books.Members.BookMember do
  @moduledoc """
  The link between a book and a user.
  It contains the role of the user for this particular book.
  """
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query

  alias App.Auth
  alias App.Books.Book
  alias App.Books.Members.Role

  @type id :: integer()

  @type t :: %__MODULE__{
          id: id(),
          book: Book.t(),
          user: Auth.User.t(),
          role: Role.t(),
          deleted_at: NaiveDateTime.t()
        }

  schema "book_members" do
    belongs_to :book, Book
    belongs_to :user, Auth.User

    field :role, Ecto.Enum, values: Role.all()
    field :deleted_at, :naive_datetime

    timestamps()
  end

  ## Changeset

  def changeset(struct, attrs) do
    struct
    |> cast(attrs, [:role])
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
    |> validate_required(:user_id)
    |> foreign_key_constraint(:user_id)
  end

  ## Query

  @spec base_query :: Ecto.Query.t()
  def base_query do
    from book_member in __MODULE__,
      as: :book_member,
      where: is_nil(book_member.deleted_at)
  end

  def join_user(query) do
    with_named_binding(query, :user, fn query ->
      join(query, :inner, [book_member: book_member], assoc(book_member, :user), as: :user)
    end)
  end

  @spec book_query(Book.t()) :: Ecto.Query.t()
  def book_query(book) do
    from base_query(), where: [book_id: ^book.id]
  end
end
