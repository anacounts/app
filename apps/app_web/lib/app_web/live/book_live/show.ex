defmodule AppWeb.BookLive.Show do
  @moduledoc """
  The book show live view.
  Displays details of a book.
  """

  use AppWeb, :live_view

  alias App.Auth.Avatars
  alias App.Books
  alias App.Books.Members

  @impl Phoenix.LiveView
  def mount(%{"book_id" => book_id}, _session, socket) do
    book = Books.get_book_of_user!(book_id, socket.assigns.current_user)
    members = Members.list_members_of_book(book)

    socket =
      assign(socket,
        page_title: book.name,
        layout_heading: gettext("Details"),
        book: book,
        members: members
      )

    {:ok, socket, layout: {AppWeb.LayoutView, "book.html"}}
  end

  @impl Phoenix.LiveView
  def handle_event("delete", _params, socket) do
    # TODO Handle errors (e.g. if the user is not allowed to delete the book)
    {:ok, _} = Books.delete_book(socket.assigns.book, socket.assigns.current_user)

    {:noreply,
     socket
     |> put_flash(:info, gettext("Book deleted successfully"))
     |> push_navigate(to: Routes.book_index_path(socket, :index))}
  end
end
