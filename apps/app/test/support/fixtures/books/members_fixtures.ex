defmodule App.Books.MembersFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `App.Books.Members` context.
  """

  alias App.Repo

  alias App.Books.BookMember

  def book_member_attributes(book, attrs \\ %{}) do
    Enum.into(attrs, %{
      book_id: book.id,
      role: :member
    })
  end

  def book_member_fixture(book) do
    struct!(BookMember, book_member_attributes(book))
    |> Repo.insert!()
  end

  def book_member_fixture(book, %_{} = user) do
    struct!(BookMember, book_member_attributes(book, %{user_id: user.id}))
    |> Repo.insert!()
  end

  def book_member_fixture(book, attrs) do
    struct!(BookMember, book_member_attributes(book, attrs))
    |> Repo.insert!()
  end

  def book_member_fixture(book, user, attrs) do
    attrs = book_member_attributes(book, Enum.into(attrs, %{user_id: user.id}))

    struct!(BookMember, attrs)
    |> Repo.insert!()
  end

  def extract_invitation_token(fun) do
    {:ok, captured_email} = fun.(&"[TOKEN]#{&1}[TOKEN]")
    [_, token | _] = String.split(captured_email.text_body, "[TOKEN]")
    token
  end
end
