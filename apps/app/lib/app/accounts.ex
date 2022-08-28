defmodule App.Accounts do
  @moduledoc """
  Deprecated module. To be replaced with `App.Books` and others.
  """
  alias App.Accounts.BookMember
  alias App.Books.Book

  alias App.Repo

  ## Members

  # TODO Maybe move to separate context?

  @doc """
  Gets a single book member.
  Raises `Ecto.NoResultsError` if the BookMember does not exist.
  ## Examples
      iex> get_member!(123)
      %BookMember{}
      iex> get_member!(456)
      ** (Ecto.NoResultsError)
  """
  def get_member!(id), do: Repo.get!(BookMember, id)

  @spec find_book_members(Book.t()) :: [BookMember.t()]
  def find_book_members(book) do
    BookMember.book_query(book)
    |> Repo.all()
  end

  @spec get_membership(Book.id(), User.t()) :: BookMember.t() | nil
  def get_membership(book_id, user) do
    Repo.get_by(BookMember, book_id: book_id, user_id: user.id)
  end
end
