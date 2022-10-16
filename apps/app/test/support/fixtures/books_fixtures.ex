defmodule App.BooksFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `App.Books` context.
  """

  import App.BalanceFixtures

  alias App.Books

  def valid_book_name, do: "A valid book name !"

  def valid_book_attributes(attrs \\ %{}) do
    Enum.into(attrs, %{
      name: valid_book_name(),
      default_balance_params: valid_balance_transfer_params_attrs()
    })
  end

  def book_fixture(user, attrs \\ %{}) do
    {:ok, book} =
      attrs
      |> valid_book_attributes()
      |> Books.create_book(user)

    # TODO There should be no preload here, rework tests
    book = App.Repo.preload(book, members: [:user])

    book
  end

  # TODO "setup_*" functions should be removed in favor of setup blocks

  # Beware, even if calling `setup_book_member_fixture`, only the creator
  # will be available in book members, since the book members aren't reloaded
  # after creating the other member
  def setup_book_fixture(%{user: user} = context) do
    Map.put(context, :book, book_fixture(user))
  end
end
