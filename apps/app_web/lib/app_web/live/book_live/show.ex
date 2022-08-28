defmodule AppWeb.BookLive.Show do
  @moduledoc """
  The book show live view.
  Displays details of a book.
  """

  use AppWeb, :live_view

  alias App.Books
  alias App.Auth.Avatars

  @impl Phoenix.LiveView
  def mount(%{"book_id" => book_id}, _session, socket) do
    book =
      Books.get_book_of_user!(book_id, socket.assigns.current_user)
      # TODO No preload here !
      |> App.Repo.preload(members: [:user])

    socket =
      assign(socket,
        page_title: book.name,
        layout_heading: gettext("Details"),
        book: book
      )

    {:ok, socket, layout: {AppWeb.LayoutView, "book.html"}}
  end

  @impl Phoenix.LiveView
  def handle_event("delete", _params, socket) do
    {:ok, _} = Books.delete_book(socket.assigns.book)

    {:noreply,
     socket
     |> put_flash(:info, gettext("Book deleted successfully"))
     |> push_redirect(to: Routes.book_index_path(socket, :index))}
  end

  defp format_code(:divide_equally), do: gettext("Divide equally")
  defp format_code(:weight_by_income), do: gettext("Weight by income")
end
