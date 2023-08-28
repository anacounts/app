defmodule App.Books.MembersFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `App.Books.Members` context.
  """

  alias App.Repo

  alias App.Books.BookMember
  alias App.Books.InvitationToken

  def book_member_attributes(attrs \\ %{}) do
    Enum.into(attrs, %{
      role: :member,
      nickname: "Member #{System.unique_integer()}"
    })
  end

  def book_member_fixture(book, attrs \\ %{}) do
    %BookMember{book_id: book.id}
    |> Map.merge(book_member_attributes(attrs))
    |> Repo.insert!()
  end

  def invitation_token_fixture(book_member, sent_to \\ default_sent_to_email()) do
    {hashed_token, invitation_token} =
      InvitationToken.build_invitation_token(book_member, sent_to)

    {hashed_token, Repo.insert!(invitation_token)}
  end

  defp default_sent_to_email, do: "sent_to#{System.unique_integer()}@example.com"

  def extract_invitation_token(fun) do
    {:ok, captured_email} = fun.(&"[TOKEN]#{&1}[TOKEN]")
    [_, token | _] = String.split(captured_email.text_body, "[TOKEN]")
    token
  end
end
