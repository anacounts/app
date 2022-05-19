defmodule Anacounts.Accounts.BookUser do
  @moduledoc """
  The link between a book and a user.
  It contains the role of the user for this particular book.
  """
  use Ecto.Schema
  import Ecto.Query

  alias Anacounts.Accounts
  alias Anacounts.Auth

  schema "accounts_book_users" do
    belongs_to :book, Accounts.Book
    belongs_to :user, Auth.User

    field :role, Ecto.Enum, values: Accounts.Role.all()
    field :deleted_at, :naive_datetime

    timestamps()
  end

  @spec base_query :: Ecto.Query.t()
  def base_query do
    from bu in __MODULE__, where: is_nil(bu.deleted_at)
  end

  @spec book_query(Accounts.Book.t()) :: Ecto.Query.t()
  def book_query(book) do
    from bu in base_query(),
      where: bu.book_id == ^book.id
  end
end
