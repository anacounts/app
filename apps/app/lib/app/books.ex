defmodule App.Books do
  @moduledoc """
  The Book context. Create, update, delete, and find books.
  """

  import Ecto.Query
  alias App.Repo

  alias App.Accounts.User
  alias App.Books.Book
  alias App.Books.BookMember
  alias App.Books.InvitationToken

  ## Database getters

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
    from [book: book] in Book.base_query(),
      join: member in BookMember,
      on: member.book_id == book.id,
      where: member.user_id == ^user.id
  end

  ## CRUD

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
        %BookMember{
          role: :creator,
          book_id: book.id,
          user_id: creator.id,
          nickname: creator.display_name,
          balance_config_id: creator.balance_config_id
        }
      end)
      |> Repo.transaction()

    case result do
      {:ok, %{book: book}} -> {:ok, book}
      {:error, :book, changeset, _changes} -> {:error, changeset}
    end
  end

  @doc """
  Updates a book.
  """
  @spec update_book(Book.t(), map()) :: {:ok, Book.t()} | {:error, Ecto.Changeset.t()}
  def update_book(book, attrs) do
    book
    |> Book.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a book.
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

  ## Invitations

  @doc """
  Get the invitation token of the book, that shall be used to invite users to the book.
  """
  @spec get_book_invitation_token(Book.t()) :: String.t()
  def get_book_invitation_token(book) do
    get_book_token(book) || insert_book_token(book)
  end

  defp get_book_token(book) do
    invitation_token =
      book
      |> InvitationToken.book_tokens_query()
      |> Repo.one()

    invitation_token && Base.url_encode64(invitation_token.token, padding: false)
  end

  defp insert_book_token(book) do
    {encoded_token, invitation_token} = InvitationToken.build_invitation_token(book)
    Repo.insert!(invitation_token)
    encoded_token
  end

  @doc """
  Get the book linked to an invitation token. Returns `nil` if the token is invalid,
  not found, or expired.
  """
  @spec get_book_by_invitation_token(String.t()) :: Book.t() | nil
  def get_book_by_invitation_token(invitation_token) do
    case InvitationToken.verify_invitation_token_query(invitation_token) do
      {:ok, query} -> Repo.one(query)
      :error -> nil
    end
  end
end
