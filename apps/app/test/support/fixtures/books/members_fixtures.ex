defmodule App.Books.MembersFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `App.Books.Members` context.
  """

  alias App.Repo

  alias App.Books.Members.BookMember

  def book_member_attributes(book, user, attrs \\ %{}) do
    Enum.into(attrs, %{
      book_id: book.id,
      user_id: user.id,
      role: :member
    })
  end

  def book_member_fixture(book, user, attrs \\ %{}) do
    struct!(BookMember, book_member_attributes(book, user, attrs))
    |> Repo.insert!()
  end
end
