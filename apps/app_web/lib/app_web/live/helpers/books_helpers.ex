defmodule AppWeb.BooksHelpers do
  @moduledoc """
  Helper functions for live views related to books.
  """
  use AppWeb, :verified_routes

  import AppWeb.Gettext
  import Phoenix.Component, only: [assign: 3]
  import Phoenix.LiveView, only: [put_flash: 3, push_navigate: 2]

  alias App.Books

  @doc """
  Handle the "delete-book" event from the book layout menu.

  Deletes the book and redirects to the book index.
  """
  @spec handle_delete_book(Phoenix.LiveView.Socket.t()) :: {:noreply, Phoenix.LiveView.Socket.t()}
  def handle_delete_book(socket) do
    Books.delete_book!(socket.assigns.book)

    {:noreply,
     socket
     |> put_flash(:info, gettext("Book deleted successfully"))
     |> push_navigate(to: ~p"/books")}
  end

  @doc """
  Handle the "close-book" event from the book layout menu.

  Closes the book and updates the socket assigns.
  """
  @spec handle_close_book(Phoenix.LiveView.Socket.t()) :: {:noreply, Phoenix.LiveView.Socket.t()}
  def handle_close_book(socket) do
    book = Books.close_book!(socket.assigns.book)

    {:noreply,
     socket
     |> put_flash(:info, gettext("Book closed successfully"))
     |> assign(:book, book)}
  end

  @doc """
  Handle the "reopen-book" event from the book layout menu.

  Reopens the book and updates the socket assigns.
  """
  @spec handle_reopen_book(Phoenix.LiveView.Socket.t()) :: {:noreply, Phoenix.LiveView.Socket.t()}
  def handle_reopen_book(socket) do
    book = Books.reopen_book!(socket.assigns.book)

    {:noreply,
     socket
     |> put_flash(:info, gettext("Book reopened successfully"))
     |> assign(:book, book)}
  end
end
