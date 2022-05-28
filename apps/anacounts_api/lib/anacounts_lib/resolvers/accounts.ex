defmodule AnacountsAPI.Resolvers.Accounts do
  @moduledoc """
  Resolve queries and mutations from
  the `AnacountsAPI.Schema.AccountTypes` module.
  """
  use AnacountsAPI, :resolver

  alias Anacounts.Accounts

  ## Accounts queries

  def find_book(_parent, %{id: id}, %{context: %{current_user: user}}) do
    Accounts.get_book(id, user) |> wrap()
  end

  def find_book(_parent, _args, _resolution), do: not_logged_in()

  def find_books(_parent, _args, %{context: %{current_user: user}} = _resolution) do
    Accounts.find_user_books(user)
    |> wrap()
  end

  def find_books(_parent, _args, _resolution), do: not_logged_in()

  ## Accounts mutations

  def do_create_book(_parent, %{attrs: book_attrs}, %{context: %{current_user: user}}) do
    Accounts.create_book(user, book_attrs)
  end

  def do_create_book(_parent, _args, _resolution), do: not_logged_in()
end
