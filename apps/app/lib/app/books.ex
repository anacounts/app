defmodule App.Books do
  @moduledoc """
  The Book context. Create, update, delete, and find books.
  """

  import Ecto.Query
  alias App.Repo

  alias App.Auth.User
  alias App.Books.Book
  alias App.Books.BookMember
  alias App.Books.Members
  alias App.Books.Rights

  @doc """
  Gets a single book.

  Raises `Ecto.NoResultsError` if the Book does not exist.

  ## Examples

      iex> get_book!(123)
      %Book{}

      iex> get_book!(456)
      ** (Ecto.NoResultsError)

  """
  @spec get_book!(Book.id()) :: Book.t()
  def get_book!(id), do: Repo.get!(Book, id)

  @doc """
  Gets a single book if it belongs to the user.

  Returns `nil` if the book does not exist or does not belong to the user.

  ## Examples

      iex> get_book_for_user!(123, user)
      %Book{}

      iex> get_book_for_user!(456, user)
      nil

  """
  @spec get_book_of_user(Book.id(), User.t()) :: Book.t() | nil
  def get_book_of_user(id, %User{} = user) do
    books_of_user_query(user)
    |> Repo.get(id)
  end

  @doc """
  Gets a single book if it belongs to the user.

  Raises `Ecto.NoResultsError` if the book does not exist or does not belong to the user.

  ## Examples

      iex> get_book_for_user!(123, user)
      %Book{}

      iex> get_book_for_user!(456, user)
      ** (Ecto.NoResultsError)

  """
  @spec get_book_of_user!(Book.id(), User.t()) :: Book.t() | nil
  def get_book_of_user!(id, %User{} = user) do
    books_of_user_query(user)
    |> Repo.get!(id)
  end

  @doc """
  Get all books a specific user belongs to.

  ## Examples

      iex> get_books_of_user(user)
      [%Book{}, ...]

  """
  @spec list_books_of_user(User.t()) :: [Book.t()]
  def list_books_of_user(%User{} = user) do
    books_of_user_query(user)
    |> Repo.all()
  end

  # Returns a query that fetches all books a user belongs to.
  @spec books_of_user_query(Auth.User.t()) :: Ecto.Query.t()
  defp books_of_user_query(%User{} = user) do
    base_query()
    |> join_members()
    |> Members.where_user_id(user.id)
  end

  @doc """
  Creates a book.

  ## Examples

      iex> create_book(%{field: value}, user_creator)
      {:ok, %Book{}}

      iex> create_book(%{field: bad_value}, user_creator)
      {:error, %Ecto.Changeset{}}

  """
  @spec create_book(map(), User.t()) :: {:ok, Book.t()} | {:error, Ecto.Changeset.t()}
  def create_book(attrs, %User{} = creator) do
    result =
      Ecto.Multi.new()
      |> Ecto.Multi.insert(:book, Book.changeset(%Book{}, attrs))
      |> Ecto.Multi.insert(:creator, fn %{book: book} ->
        %BookMember{role: :creator, book_id: book.id, user_id: creator.id}
      end)
      |> Repo.transaction()

    case result do
      {:ok, %{book: book}} -> {:ok, book}
      {:error, :book, changeset, _changes} -> {:error, changeset}
    end
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

  ## Queries

  defp base_query do
    from book in Book,
      as: :book,
      where: is_nil(book.deleted_at)
  end

  defp join_members(query, qual \\ :inner) do
    with_named_binding(query, :book_member, fn query ->
      join(query, qual, [book: book], member in BookMember,
        on: member.book_id == book.id,
        as: :book_member
      )
    end)
  end
end
