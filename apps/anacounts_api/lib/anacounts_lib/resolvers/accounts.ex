defmodule AnacountsAPI.Resolvers.Accounts do
  @moduledoc """
  Resolve queries and mutations from
  the `AnacountsAPI.Schema.AccountTypes` module.
  """
  use AnacountsAPI, :resolver

  alias Anacounts.Accounts

  ## Queries

  def find_book(_parent, %{id: id}, %{context: %{current_user: user}}) do
    fetch_book(id, user)
  end

  def find_book(_parent, _args, _resolution), do: not_logged_in()

  def find_books(_parent, _args, %{context: %{current_user: user}} = _resolution) do
    {:ok, Accounts.find_user_books(user)}
  end

  def find_books(_parent, _args, _resolution), do: not_logged_in()

  ## Mutations

  def do_create_book(_parent, %{attrs: book_attrs}, %{context: %{current_user: user}}) do
    Accounts.create_book(user, book_attrs)
  end

  def do_create_book(_parent, _args, _resolution), do: not_logged_in()

  def do_delete_book(_parent, %{id: id}, %{context: %{current_user: user}}) do
    with {:ok, book} <- fetch_book(id, user),
         {:ok, member} <- fetch_membership(id, user),
         :ok <- has_rights?(member, :delete_book) do
      Accounts.delete_book(book)
    end
  end

  def do_delete_book(_parent, _args, _resolution), do: not_logged_in()

  def do_invite_user(_parent, %{book_id: book_id, email: email}, %{context: %{current_user: user}}) do
    with {:ok, member} <- fetch_membership(book_id, user),
         :ok <- has_rights?(member, :invite_new_member) do
      Accounts.Members.invite_user(book_id, email)
    end
  end

  def do_invite_user(_parent, _args, _resolution), do: not_logged_in()

  defp fetch_book(book_id, user) do
    if book = Accounts.get_book_of_user(book_id, user) do
      {:ok, book}
    else
      {:error, :not_found}
    end
  end

  defp fetch_membership(book_id, user) do
    if member = Accounts.get_membership(book_id, user) do
      {:ok, member}
    else
      {:error, :not_found}
    end
  end

  defp has_rights?(member, right) do
    if Accounts.Rights.member_has_right?(member, right) do
      :ok
    else
      {:error, :unauthorized}
    end
  end

  ## External field resolution

  def find_book_members(book, _args, _resolution) do
    {:ok, Anacounts.Accounts.find_book_members(book)}
  end

  def find_money_transfer_book(%{book_id: book_id}, _args, _resolution) do
    {:ok, Accounts.get_book!(book_id)}
  end

  def find_money_transfer_holder(%{holder_id: holder_id}, _args, _resolution) do
    {:ok, Accounts.get_member!(holder_id)}
  end

  def find_transfer_peer_user(%{member_id: member_id}, _args, _resolution) do
    {:ok, Accounts.get_member!(member_id)}
  end
end
