defmodule AppWeb.BookAccess do
  @moduledoc """
  This module provides access checking for books.
  """

  alias App.Books
  alias App.Books.Members

  @doc """
  * :ensure_book
  Assigns `:book` and `:current_member` to the socket assigns based on the `"book_id"`
  parameter if the current user is a member of the book.
  Raises `Ecto.NoResultsError` if the book does not exist or the user is not a member.

  ## Examples
  # In a LiveView file
  defmodule AppWeb.PageLive do
    use AppWeb, :live_view

    plug {AppWeb.BookAccess, :ensure_book!}

  """
  def on_mount(:ensure_book!, params, _session, socket) do
    {:cont,
     socket
     |> mount_book!(params)
     |> mount_current_member!()}
  end

  defp mount_book!(socket, %{"book_id" => book_id}) do
    Phoenix.Component.assign_new(socket, :book, fn ->
      Books.get_book!(book_id)
    end)
  end

  defp mount_current_member!(socket) do
    Phoenix.Component.assign_new(socket, :current_member, fn ->
      %{book: book, current_user: current_user} = socket.assigns
      Members.get_membership!(book, current_user)
    end)
  end
end
