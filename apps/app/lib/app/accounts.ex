defmodule App.Accounts do
  @moduledoc """
  Manage books and related information.
  Allows to create a book, add or remove money transfers, add users, ...
  """

  alias App.Repo

  alias App.Accounts.Book
  alias App.Accounts.BookMember
  alias App.Auth.User

  # TODO Delete get_book_of_user/2 and get_book_of_user!/2

  @spec get_book_of_user(Book.id(), User.t()) :: Book.t() | nil
  def get_book_of_user(id, user) do
    Book.user_query(user)
    |> Repo.get(id)
  end

  @spec get_book_of_user!(Book.id(), User.t()) :: Book.t() | nil
  def get_book_of_user!(id, user) do
    Book.user_query(user)
    |> Repo.get!(id)
  end

  @doc """
  Gets a single book.

  Raises `Ecto.NoResultsError` if the Book does not exist.

  ## Examples

      iex> get_book!(123)
      %Book{}

      iex> get_book!(456)
      ** (Ecto.NoResultsError)

  """
  def get_book!(id), do: Repo.get!(Book, id)

  @doc """
  Get all books of a specific user, whatever role they may have.
  """
  @spec find_user_books(User.t()) :: [Book.t()]
  def find_user_books(user) do
    Book.user_query(user)
    # TODO preload shouldn't be necessary since we only display the number of members
    # See templates/books/index.html.heex:18
    |> Book.preload_members()
    |> Repo.all()
  end

  # TODO Should be create_book/1

  @doc """
  Creates a book.

  ## Examples

      iex> create_book(user, %{field: value})
      {:ok, %Book{}}

      iex> create_book(user, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  @spec create_book(User.t(), map()) :: {:ok, Book.t()} | {:error, Ecto.Changeset.t()}
  def create_book(user, attrs) do
    %Book{}
    |> Book.create_changeset(user, attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a book.

  ## Examples

      iex> update_book(book, %{field: new_value})
      {:ok, %Book{}}

      iex> update_book(book, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  @spec update_book(Book.t(), map()) :: {:ok, Book.t()} | {:error, Ecto.Changeset.t()}
  def update_book(book, attrs) do
    book
    |> Book.changeset(attrs)
    |> Repo.update()
  end

  # TODO delete_book should actually delete the book, another function could soft delete it

  @doc """
  Deletes a book.

  ## Examples

      iex> delete_book(book)
      {:ok, %Book{}}

      iex> delete_book(book)
      {:error, %Ecto.Changeset{}}

  """
  @spec delete_book(Book.t()) :: {:ok, Book.t()} | {:error, Ecto.Changeset.t()}
  def delete_book(%Book{} = book) do
    book
    |> Book.delete_changeset()
    |> Repo.update()
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking book changes.

  ## Examples

      iex> change_book(book)
      %Ecto.Changeset{data: %Book{}}

  """
  def change_book(%Book{} = book, attrs \\ %{}) do
    Book.changeset(book, attrs)
  end

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
