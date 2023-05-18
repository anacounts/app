defmodule AppWeb.BooksLive do
  @moduledoc """
  The book index live view.
  List all books the user is member of.
  """

  use AppWeb, :live_view

  alias App.Books

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <main class="max-w-prose mx-auto">
      <.alert
        :for={{type, message} <- @flash}
        type={type}
        phx-click="lv:clear-flash"
        phx-value-key={type}
      >
        <%= message %>
      </.alert>

      <.tile :if={Enum.empty?(@books)} class="text-xl" navigate={~p"/books/new"}>
        <.icon name="add" />
        <%= gettext("Create your first book") %>
      </.tile>
      <.tile :for={book <- @books} navigate={~p"/books/#{book.id}/transfers"} data-book-id={book.id}>
        <.avatar src={~p"/images/book-default-avatar.png"} alt="" />
        <div class="grow text-lg line-clamp-2"><%= book.name %></div>
        <.button color={:ghost} class="shrink-0 hover:bg-transparent">
          <.icon name="chevron-right" alt={gettext("Open")} />
        </.button>
      </.tile>

      <.fab_container>
        <:item>
          <.fab navigate={~p"/books/new"}>
            <.icon name="add" alt={gettext("Create a new book")} />
          </.fab>
        </:item>
      </.fab_container>
    </main>
    """
  end

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    books = Books.list_books_of_user(socket.assigns.current_user)
    {:ok, assign(socket, :books, books), layout: {AppWeb.Layouts, :home}}
  end

  @impl Phoenix.LiveView
  def handle_params(_params, _url, socket) do
    {:noreply, assign(socket, :page_title, gettext("My books"))}
  end
end
