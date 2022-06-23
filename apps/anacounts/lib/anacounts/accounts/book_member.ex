defmodule Anacounts.Accounts.BookMember do
  @moduledoc """
  The link between a book and a user.
  It contains the role of the user for this particular book.
  """
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query

  alias Anacounts.Accounts
  alias Anacounts.Auth

  @type id :: integer()

  @type t :: %__MODULE__{
          id: id(),
          book: Accounts.Book.t(),
          user: Auth.User.t(),
          role: Accounts.Role.t(),
          deleted_at: NaiveDateTime.t()
        }

  schema "accounts_book_members" do
    belongs_to :book, Accounts.Book
    belongs_to :user, Auth.User

    field :role, Ecto.Enum, values: Accounts.Role.all()
    field :deleted_at, :naive_datetime

    timestamps()
  end

  def create_changeset(attrs) do
    %__MODULE__{}
    |> cast(attrs, [:role, :book_id, :user_id])
    |> validate_required([:role, :book_id, :user_id])
    |> foreign_key_constraint(:book_id)
    |> foreign_key_constraint(:user_id)
    |> unique_constraint([:book_id, :user_id],
      message: "user is already a member of this book",
      error_key: :user_id
    )
  end

  @spec base_query :: Ecto.Query.t()
  def base_query do
    from bm in __MODULE__, where: is_nil(bm.deleted_at)
  end

  @spec book_query(Accounts.Book.t()) :: Ecto.Query.t()
  def book_query(book) do
    from base_query(), where: [book_id: ^book.id]
  end
end
