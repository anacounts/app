defmodule Anacounts.AccountsFixtures do
  alias Anacounts.Accounts

  def valid_book_name, do: "A valid book name !"
  def invalid_book_name, do: nil

  def valid_book_attributes(attrs \\ %{}) do
    Map.merge(attrs, %{
      name: valid_book_name()
    })
  end

  def invalid_book_attributes(attrs \\ %{}) do
    Map.merge(attrs, %{
      name: invalid_book_name()
    })
  end

  def book_fixture(user, attrs \\ %{}) do
    {:ok, book} =
      attrs
      |> valid_book_attributes()
      |> then(&Accounts.create_book(user, &1))

    book
  end

  def setup_book_fixture(%{user: user} = context) do
    Map.put(context, :book, book_fixture(user))
  end
end
