defmodule App.Accounts.Members do
  @moduledoc """
  List members of a book.
  Add and remove some, or edit their roles.
  """

  alias App.Repo

  alias App.Accounts
  alias App.Accounts.BookMember
  alias App.Auth

  @doc """
  Invite a user to an existing book.
  """
  @spec invite_user(Accounts.Book.id(), String.t()) :: BookMember.t()
  def invite_user(book_id, user_email) do
    user =
      Auth.get_user_by_email(user_email) ||
        raise "User with email does not exist, crashing as inviting external people is not supported yet"

    add_member(book_id, user)
  end

  defp add_member(book_id, user) do
    %{
      # set the member role as default, it can be changed later
      role: :member,
      book_id: book_id,
      user_id: user.id
    }
    |> BookMember.create_changeset()
    |> Repo.insert()
  end
end
