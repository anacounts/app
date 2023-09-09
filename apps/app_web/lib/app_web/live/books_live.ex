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
    <main class="flex justify-center mx-auto">
      <div class="grow basis-3/4 max-w-prose">
        <div class="md:hidden text-right">
          <.button color={:ghost} phx-click={show_dialog("#filters")}>
            <.icon name="tune" />
          </.button>
        </div>

        <.tile :if={Enum.empty?(@books)} summary_class="text-xl" navigate={~p"/books/new"}>
          <.icon name="add" />
          <%= gettext("Create your first book") %>
        </.tile>
        <.tile :for={book <- @books} navigate={~p"/books/#{book.id}/transfers"} data-book-id={book.id}>
          <.avatar src={~p"/images/book-default-avatar.png"} alt="" />
          <div class="grow text-lg line-clamp-2"><%= book.name %></div>
        </.tile>
      </div>

      <.filters id="filters" phx-change="filter">
        <:section icon="arrow_downward" title={gettext("Sort by")}>
          <.filter_options field={@filters[:sort_by]} options={sort_by_options()} />
        </:section>

        <:section icon="filter_alt" title={gettext("Filter by")}>
          <.filter_options field={@filters[:owned_by]} options={owned_by_options()} />
        </:section>
      </.filters>

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

    filters =
      to_form(
        %{
          "sort_by" => "last_created",
          "owned_by" => "anyone"
        },
        as: :filters
      )

    socket =
      assign(socket,
        page_title: gettext("My books"),
        books: books,
        filters: filters
      )

    {:ok, socket, layout: {AppWeb.Layouts, :home}, temporary_assigns: [books: [], filters: nil]}
  end

  @impl Phoenix.LiveView
  def handle_event("filter", %{"filters" => filters}, socket) do
    books = Books.list_books_of_user(socket.assigns.current_user, filters)

    socket =
      assign(socket,
        books: books,
        filters: to_form(filters, as: :filters)
      )

    {:noreply, socket}
  end

  defp sort_by_options do
    [
      {gettext("Last created"), "last_created"},
      {gettext("First created"), "first_created"},
      {gettext("Alphabetically"), "alphabetically"}
    ]
  end

  defp owned_by_options do
    [
      {gettext("Owned by anyone"), "anyone"},
      {gettext("Owned by me"), "me"},
      {gettext("Not owned by me"), "others"}
    ]
  end
end
