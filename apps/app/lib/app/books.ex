defmodule App.Books do
  @moduledoc """
  The Book context. Create, update, delete, and find books.
  """

  alias App.Repo

  alias App.Auth.User
  alias App.Books.Book
  alias App.Books.Members
  alias App.Books.Members.Rights

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
  Updates a book if the user is allowed to do so.

  ## Examples

      iex> update_book(book, user, %{field: new_value})
      {:ok, %Book{}}

      iex> update_book(book, user, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

      iex> update_book(book, not_allowed_user, %{field: bad_value})
      {:error, :unauthorized}

  """
  @spec update_book(Book.t(), User.t(), map()) ::
          {:ok, Book.t()} | {:error, Ecto.Changeset.t()} | {:error, :unauthorized}
  def update_book(book, user, attrs) do
    with %{} = member <- Members.get_membership(book.id, user.id),
         true <- Rights.member_can_update_book?(member) do
      book
      |> Book.changeset(attrs)
      |> Repo.update()
    else
      _ -> {:error, :unauthorized}
    end
  end

  # TODO delete_book should actually delete the book, another function could soft delete it

  @doc """
  Deletes a book if the user is allowed to do so.

  ## Examples

      iex> delete_book(book, user)
      {:ok, %Book{}}

      iex> delete_book(book, user)
      {:error, %Ecto.Changeset{}}

      iex> delete_book(book, not_allowed_user)
      {:error, :unauthorized}

  """
  @spec delete_book(Book.t(), User.t()) ::
          {:ok, Book.t()} | {:error, Ecto.Changeset.t()} | {:error, :unauthorized}
  def delete_book(%Book{} = book, %User{} = user) do
    with %{} = member <- Members.get_membership(book.id, user.id),
         true <- Rights.member_can_delete_book?(member) do
      book
      |> Book.delete_changeset()
      |> Repo.update()
    else
      _ -> {:error, :unauthorized}
    end
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
end
