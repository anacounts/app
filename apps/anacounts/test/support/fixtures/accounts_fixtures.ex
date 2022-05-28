defmodule Anacounts.AccountsFixtures do
  @moduledoc """
  Fixtures for the `Accounts` context
  """

  def valid_book_name, do: "A valid book name !"

  def valid_book_attributes(attrs \\ %{}) do
    Map.merge(attrs, %{
      name: valid_book_name()
    })
  end

  def book_fixture(user, attrs \\ %{}) do
    {:ok, book} =
      attrs
      |> valid_book_attributes()
      |> then(&Anacounts.Accounts.create_book(user, &1))

    book
  end

  def setup_book_fixture(%{user: user} = context) do
    Map.put(context, :book, book_fixture(user))
  end
end