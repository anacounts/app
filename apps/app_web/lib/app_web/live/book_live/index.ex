defmodule AppWeb.BookLive.Index do
  @moduledoc """
  The book index live view.
  List all books the user is member of.
  """

  use AppWeb, :live_view

  alias App.Books

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    books = Books.list_books_of_user(socket.assigns.current_user)
    {:ok, assign(socket, :books, books), layout: {AppWeb.LayoutView, :home}}
  end

  @impl Phoenix.LiveView
  def handle_params(_params, _url, socket) do
    {:noreply, assign(socket, :page_title, gettext("My books"))}
  end
end
