defmodule App.Books.MembersFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `App.Books.Members` context.
  """

  alias App.Books.Members

  @doc """
  Generate a book_member.
  """
  def book_member_fixture(book, user) do
    # XXX In the end, `invite_new_member` will only send an invite
    # Use a function that will actually create the membership of the user
    {:ok, book_member} = Members.invite_new_member(book.id, user.email)

    book_member
  end

  def setup_book_member_fixture(%{book: book} = context) do
    book_member_user = App.AuthFixtures.user_fixture()

    context
    |> Map.put(:book_member_user, book_member_user)
    |> Map.put(:book_member, book_member_fixture(book, book_member_user))
  end
end
