defmodule App.Books.Members do
  @moduledoc """
  The Books.Members context.
  """

  import Ecto.Query
  alias App.Repo

  alias App.Accounts.User
  alias App.Books.Book
  alias App.Books.BookMember

  @doc """
  Gets a single book_member.

  Raises `Ecto.NoResultsError` if the book member does not exist.
  """
  @spec get_book_member!(BookMember.id()) :: BookMember.t()
  def get_book_member!(id) do
    BookMember.base_query()
    |> BookMember.select_display_name()
    |> Repo.get!(id)
  end

  @doc """
  Lists all members of a book.
  """
  @spec list_members_of_book(Book.t()) :: [BookMember.t()]
  def list_members_of_book(book) do
    members_of_book_query(book)
    |> Repo.all()
  end

  @doc """
  Get a single member of a book.

  Raises `Ecto.NoResultsError` if the book member does not exist or
  is not a member of the book.
  """
  @spec get_member_of_book!(BookMember.id(), Book.t()) :: BookMember.t()
  def get_member_of_book!(id, book) do
    members_of_book_query(book)
    |> where([book_member: book_member], book_member.id == ^id)
    |> Repo.one!()
  end

  defp members_of_book_query(book) do
    from([book_member: book_member] in BookMember.base_query(),
      left_join: user in assoc(book_member, :user),
      where: book_member.book_id == ^book.id,
      order_by: [asc: coalesce(user.display_name, book_member.nickname)]
    )
    |> BookMember.select_display_name()
    |> BookMember.select_email()
  end

  @doc """
  Get the book member entity linking a user to a book.

  Returns `nil` if the user is not a member of the book.

  ## Examples

      iex> get_book_member_of_user(book.id, user.id)
      %BookMember{}

      iex> get_book_member_of_user(book.id, non_member_user.id)
      nil

  """
  # TODO use entities instead of ids
  @spec get_membership(Book.id(), User.id()) :: BookMember.t() | nil
  def get_membership(book_id, user_id) do
    Repo.get_by(BookMember, book_id: book_id, user_id: user_id)
  end

  @doc """
  Get the book member entity linking a user to a book.

  Raises `Ecto.NoResultsError` if the user is not a member of the book.

  ## Examples

      iex> get_book_member_of_user!(book.id, user.id)
      %BookMember{}

      iex> get_book_member_of_user!(book.id, non_member_user.id)
      ** (Ecto.NoResultsError)

  """
  @spec get_membership!(Book.t(), User.t()) :: BookMember.t() | nil
  def get_membership!(%Book{} = book, %User{} = user) do
    Repo.get_by(BookMember, book_id: book.id, user_id: user.id)
  end

  @doc """
  Create a new book member within a book.
  """
  @spec create_book_member(Book.t(), map()) ::
          {:ok, BookMember.t()} | {:error, Ecto.Changeset.t()}
  def create_book_member(%Book{} = book, attrs) do
    %BookMember{
      book_id: book.id,
      role: :member
    }
    |> BookMember.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Update a book member.
  """
  @spec update_book_member(BookMember.t(), map()) ::
          {:ok, BookMember.t()} | {:error, Ecto.Changeset.t()}
  def update_book_member(book_member, attrs) do
    book_member
    |> BookMember.changeset(attrs)
    |> Repo.update()
  end

  @spec deprecated_change_book_member(BookMember.t(), map()) :: Ecto.Changeset.t(BookMember.t())
  def deprecated_change_book_member(book_member, attrs \\ %{}) do
    BookMember.deprecated_changeset(book_member, attrs)
  end

  @doc """
  Return an `%Ecto.Changeset{}` for tracking book member changes.
  """
  @spec change_book_member(BookMember.t(), map()) :: Ecto.Changeset.t(BookMember.t())
  def change_book_member(book_member, attrs \\ %{}) do
    BookMember.changeset(book_member, attrs)
  end
end
