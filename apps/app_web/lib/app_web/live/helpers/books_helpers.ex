defmodule AppWeb.BooksHelpers do
  @moduledoc """
  Helper functions for live views related to books.
  """
  use AppWeb, :verified_routes

  import AppWeb.Gettext
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
end
