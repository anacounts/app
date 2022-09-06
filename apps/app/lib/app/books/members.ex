defmodule App.Books.Members do
  @moduledoc """
  The Books.Members context.
  """

  import Ecto.Query, warn: false
  alias App.Repo

  alias App.Auth
  alias App.Books.Members.BookMember

  @doc """
  Invite a user to an existing book.

  # TODO This is a temporary solution until we have a proper invitation system.
  """
  @spec invite_new_member(Book.id(), String.t()) :: BookMember.t()
  def invite_new_member(book_id, user_email) do
    user =
      Auth.get_user_by_email(user_email) ||
        raise "User with email does not exist, crashing as inviting external people is not supported yet"

    create_book_member(book_id, user)
  end

  defp create_book_member(book_id, user) do
    %{
      # set the member role as default, it can be changed later
      role: :member,
      book_id: book_id,
      user_id: user.id
    }
    |> BookMember.create_changeset()
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
  def get_book_member!(id), do: Repo.get!(BookMember, id)

  @doc """
  Get the book member entity linking a user to a book.

  Returns `nil` if the user is not a member of the book.

  ## Examples

      iex> get_book_member_of_user(book.id, user.id)
      %BookMember{}
      iex> get_book_member_of_user(book.id, non_member_user.id)
      nil

  """
  def get_membership(book_id, user_id) do
    Repo.get_by(BookMember, book_id: book_id, user_id: user_id)
  end
end
