defmodule AppWeb.BookLive.Show do
  @moduledoc """
  The book show live view.
  Displays details of a book.
  """

  use AppWeb, :live_view

  alias App.Accounts
  alias App.Auth.Avatars

  @impl Phoenix.LiveView
  def mount(%{"book_id" => book_id}, _session, socket) do
    book =
      Accounts.get_book_of_user!(book_id, socket.assigns.current_user)
      # TODO No preload here !
      |> App.Repo.preload(members: [:user])

    socket = assign(socket, :book, book)

    {:ok, socket, layout: {AppWeb.LayoutView, "book.html"}}
  end

  @impl Phoenix.LiveView
  def handle_params(_params, _url, socket) do
    {:noreply, assign(socket, :page_title, gettext("Book"))}
  end

  @impl Phoenix.LiveView
  def handle_event("delete", _params, socket) do
    {:ok, _} = Accounts.delete_book(socket.assigns.book)

    {:noreply,
     socket
     |> put_flash(:info, gettext("Book deleted successfully"))
     |> push_redirect(to: Routes.book_index_path(socket, :index))}
  end
end
