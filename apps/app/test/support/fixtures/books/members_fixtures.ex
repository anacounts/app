defmodule App.Books.MembersFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `App.Books.Members` context.
  """

  alias App.Books.BookMember
  alias App.Books.Members

  def book_member_attributes(book, attrs \\ %{}) do
    Enum.into(attrs, %{
      book_id: book.id,
      role: :member
    })
  end

  def book_member_fixture(book, attrs \\ %{}) do
    attrs_map = Enum.into(attrs, %{})
    virtual_fields = Map.take(attrs_map, BookMember.__schema__(:virtual_fields))

    {:ok, book_member} = Members.create_book_member(book, book_member_attributes(book, attrs_map))

    Map.merge(book_member, virtual_fields)
  end

  def extract_invitation_token(fun) do
    {:ok, captured_email} = fun.(&"[TOKEN]#{&1}[TOKEN]")
    [_, token | _] = String.split(captured_email.text_body, "[TOKEN]")
    token
  end
end
