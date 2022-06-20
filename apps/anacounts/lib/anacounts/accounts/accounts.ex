defmodule Anacounts.Accounts do
  @moduledoc """
  Manage books and related information.
  Allows to create a book, add or remove money transfers, add users, ...
  """

  import Ecto.Query

  alias Anacounts.Repo

  alias Anacounts.Accounts.Book
  alias Anacounts.Accounts.BookMember
  alias Anacounts.Auth.User

  @spec get_book(Book.id(), User.t()) :: Book.t() | nil
  def get_book(id, user) do
    Book.user_query(user)
    |> Repo.get(id)
  end

  @doc """
  Get all books of a specific user, whatever role they may have.
  """
  @spec find_user_books(User.t()) :: [Book.t()]
  def find_user_books(user) do
    Book.user_query(user)
    |> Repo.all()
  end

  @spec find_book_members(Book.t()) :: [BookMember.t()]
  def find_book_members(book) do
    query =
      from ub in BookMember.book_query(book),
        join: u in assoc(ub, :user),
        preload: [user: u]

    Repo.all(query)
  end

  @doc """
  Create a new book.
  The book is given a name and a user that is considered its creator.
  """
  @spec create_book(User.t(), map()) :: {:ok, Book.t()} | {:error, Ecto.Changeset.t()}
  def create_book(user, attrs) do
    %Book{}
    |> Book.create_changeset(user, attrs)
    |> Repo.insert()
  end

  @spec delete_book(Book.t()) :: {:ok, Book.t()} | {:error, Ecto.Changeset.t()}
  def delete_book(book) do
    book
    |> Book.delete_changeset()
    |> Repo.update()
  end

  @spec get_membership(Book.id(), User.t()) :: BookMember.t() | nil
  def get_membership(book_id, user) do
    Repo.get_by(BookMember, book_id: book_id, user_id: user.id)
  end
end
