defmodule Anacounts.AccountsFixtures do
  @moduledoc """
  Fixtures for the `Accounts` context
  """

  import Anacounts.Accounts.BalanceFixtures

  alias Anacounts.Accounts

  def valid_book_name, do: "A valid book name !"

  def valid_book_attributes(attrs \\ %{}) do
    Enum.into(attrs, %{
      name: valid_book_name(),
      default_balance_params: valid_transfer_params()
    })
  end

  def book_fixture(user, attrs \\ %{}) do
    {:ok, book} =
      attrs
      |> valid_book_attributes()
      |> then(&Accounts.create_book(user, &1))

    book
  end

  def book_member_fixture(book, user) do
    # XXX In the end, `invite_user` will only send an invite
    # Use a function that will actually create the membership of the user
    {:ok, book_member} = Accounts.Members.invite_user(book.id, user.email)

    book_member
  end

  def setup_book_fixture(%{user: user} = context) do
    Map.put(context, :book, book_fixture(user))
  end

  def setup_book_member_fixture(%{book: book} = context) do
    book_member_user = Anacounts.AuthFixtures.user_fixture()

    context
    |> Map.put(:book_member_user, book_member_user)
    |> Map.put(:book_member, book_member_fixture(book, book_member_user))
  end
end
