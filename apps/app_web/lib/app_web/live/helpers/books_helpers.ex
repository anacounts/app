defmodule AppWeb.BooksHelpers do
  @moduledoc """
  Helper functions for live views related to books.
  """
  use AppWeb, :gettext
  use AppWeb, :verified_routes

  import Phoenix.LiveView, only: [put_flash: 3, push_navigate: 2]

  @doc """
  Redirects to the book index and shows a flash message indicating that
  the page is not accessible as the book is closed.
  """
  def closed_book_redirect(socket) do
    socket
    |> put_flash(:error, gettext("This page is not accessible while the book is closed"))
    |> push_navigate(to: ~p"/books/#{socket.assigns.book}/members")
  end
end
