defmodule AppWeb.BookAccess do
  @moduledoc """
  This module provides access checking for books.
  """
  use AppWeb, :verified_routes

  alias App.Balance
  alias App.Books
  alias App.Books.Members

  alias AppWeb.BooksHelpers

  @doc """
  * :ensure_book!
  Assigns `:book` to the socket assigns based on the `"book_id"` parameter if the
  current user is a member of the book.
  Raises `Ecto.NoResultsError` if the book does not exist or the user is not a member.

  * :ensure_open_book!
  Makes sure the book is open. Redirects to the book members page if it is closed.

  * :assign_book_members
  Assigns `:book_members` to the socket assigns based on the `:book` assign. Fills
  the balance of the members.

  * :assign_book_unbalanced
  Assigns `:book_unbalanced?` to the socket assigns based on the `:book_members` assign.
  Requires the `:book_members` balance to be filled.

  * :ensure_book_member!
  Assigns `:book_member` to the socket assigns based on the `"book_member_id"` parameter.
  Raises `Ecto.NoResultsError` if the book member does not exist.

  ## Examples

    defmodule AppWeb.PageLive do
      use AppWeb, :live_view

      on_mount {AppWeb.BookAccess, :ensure_book!}
      on_mount {AppWeb.BookAccess, :ensure_book_member!}

  """
  def on_mount(:ensure_book!, params, _session, socket) do
    {:cont, mount_book!(socket, params)}
  end

  def on_mount(:ensure_open_book!, _params, _session, socket) do
    if Books.closed?(socket.assigns.book) do
      {:halt, BooksHelpers.closed_book_redirect(socket)}
    else
      {:cont, socket}
    end
  end

  def on_mount(:assign_book_members, _params, _session, socket) do
    {:cont, mount_book_members(socket)}
  end

  def on_mount(:assign_book_unbalanced, _params, _session, socket) do
    {:cont, mount_book_unbalanced?(socket)}
  end

  def on_mount(:ensure_book_member!, params, _session, socket) do
    {:cont, mount_book_member!(socket, params)}
  end

  defp mount_book!(socket, %{"book_id" => book_id}) do
    Phoenix.Component.assign_new(socket, :book, fn ->
      Books.get_book!(book_id)
    end)
  end

  defp mount_book_members(socket) do
    Phoenix.Component.assign_new(socket, :book_members, fn ->
      socket.assigns.book
      |> Members.list_members_of_book()
      |> Balance.fill_members_balance()
    end)
  end

  defp mount_book_unbalanced?(socket) do
    Phoenix.Component.assign_new(socket, :book_unbalanced?, fn ->
      Balance.unbalanced?(socket.assigns.book_members)
    end)
  end

  defp mount_book_member!(socket, %{"book_member_id" => book_member_id}) do
    Phoenix.Component.assign_new(socket, :book_member, fn ->
      Members.get_member_of_book!(book_member_id, socket.assigns.book)
    end)
  end
end
