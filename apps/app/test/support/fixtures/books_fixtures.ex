defmodule App.BooksFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `App.Books` context.
  """

  import App.BalanceFixtures

  alias App.Repo

  alias App.Books.Book

  def book_attributes(attrs \\ %{}) do
    Enum.into(attrs, %{
      name: "A valid book name !",
      default_balance_params: transfer_params_attributes()
    })
  end

  def book_fixture(attrs \\ %{}) do
    struct!(Book, book_attributes(attrs))
    |> Repo.insert!()
  end
end
