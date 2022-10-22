defmodule App.Books.Members do
  @moduledoc """
  The Books.Members context.
  """

  import Ecto.Query, warn: false
  alias App.Repo

  alias App.Auth
  alias App.Auth.User
  alias App.Books.Members
  alias App.Books.Members.BookMember
  alias App.Books.Members.Rights

  @doc """
  Invite a user to an existing book.

  # TODO This is a temporary solution until we have a proper invitation system.
  """
  @spec invite_new_member(Book.id(), User.t(), String.t()) ::
          {:ok, BookMember.t()} | {:error, Ecto.Changeset.t()} | {:error, :unauthorized}
  def invite_new_member(book_id, %User{} = user, user_email) do
    with %{} = member <- Members.get_membership(book_id, user.id),
         true <- Rights.member_can_invite_new_member?(member) do
      user =
        Auth.get_user_by_email(user_email) ||
          raise "User with email does not exist, crashing as inviting external people is not supported yet"

      create_book_member(book_id, user)
    else
      _ -> {:error, :unauthorized}
    end
  end

  defp create_book_member(book_id, user) do
    %BookMember{
      book_id: book_id,
      user_id: user.id
    }
    # set the member role as default, it can be changed later
    |> BookMember.changeset(%{role: :member})
    |> Repo.insert()
  end

  @doc """
  Gets a single book_member.

  Raises `Ecto.NoResultsError` if the Book member does not exist.

  ## Examples

      iex> get_book_member!(123)
      %BookMember{}

      iex> get_book_member!(456)
      ** (Ecto.NoResultsError)

  """
  def get_book_member!(id) do
    base_query()
    |> with_display_name_query()
    |> Repo.get!(id)
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
  @spec get_membership(Book.id(), User.id()) :: BookMember.t() | nil
  def get_membership(book_id, user_id) do
    Repo.get_by(BookMember, book_id: book_id, user_id: user_id)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking book member changes.

  ## Examples

      iex> change_book_member(book_member)
      %Ecto.Changeset{data: %BookMember{}}

  """
  @spec change_book_member(BookMember.t(), map()) :: Ecto.Changeset.t(BookMember.t())
  def change_book_member(book_member, attrs \\ %{}) do
    BookMember.changeset(book_member, attrs)
  end

  ## Queries

  defp base_query do
    from BookMember, as: :book_member
  end

  # Load `:display_name` virtual field. Only works if querying BookMember entities.
  defp with_display_name_query(query) do
    from [user: user] in join_user(query),
      select_merge: %{display_name: user.display_name}
  end

  def join_user(query) do
    with_named_binding(query, :user, fn query ->
      join(query, :inner, [book_member: book_member], assoc(book_member, :user), as: :user)
    end)
  end
end
