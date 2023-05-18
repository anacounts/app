defmodule AppWeb.BookFormLive do
  @moduledoc """
  The book form live view.
  Create or update a book.
  """

  use AppWeb, :live_view

  alias App.Books
  alias App.Books.Book

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <.page_header back_to={@back_to}>
      <:title>
        <%= if @live_action == :new,
          do: gettext("New Book"),
          else: gettext("Edit Book") %>
      </:title>
    </.page_header>

    <main class="mx-4">
      <.form :let={f} for={@changeset} id="book-form" phx-change="validate" phx-submit="save">
        <.input type="text" label={gettext("Name")} field={f[:name]} />

        <.label>
          <%= gettext("How to balance by default?") %>
          <% # TODO Set value from changeset %>
          <select name="book[default_balance_params][means_code]">
            <option value="divide_equally"><%= gettext("Divide equally") %></option>
            <option value="weight_by_income"><%= gettext("Weight by income") %></option>
          </select>
          <.error :for={msg <- f[:default_balance_params].errors}><%= msg %></.error>
        </.label>

        <div>
          <.button color={:cta} phx-disable-with={gettext("Saving...")}>
            <%= gettext("Save") %>
          </.button>
        </div>
      </.form>
    </main>
    """
  end

  @impl Phoenix.LiveView
  def mount(params, _session, socket) do
    {:ok, mount_action(socket, socket.assigns.live_action, params)}
  end

  defp mount_action(socket, :new, _params) do
    book = %Book{}

    assign(socket,
      page_title: gettext("New Book"),
      back_to: ~p"/books",
      book: book,
      changeset: Books.change_book(book)
    )
  end

  defp mount_action(socket, :edit, %{"book_id" => book_id}) do
    book = Books.get_book_of_user!(book_id, socket.assigns.current_user)

    assign(socket,
      page_title: gettext("Edit Book · %{name}", name: book.name),
      back_to: ~p"/books/#{book}/transfers",
      book: book,
      changeset: Books.change_book(book)
    )
  end

  @impl Phoenix.LiveView
  def handle_event("validate", %{"book" => book_params}, socket) do
    changeset =
      socket.assigns.book
      |> Books.change_book(book_params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, :changeset, changeset)}
  end

  def handle_event("save", %{"book" => book_params}, socket) do
    save_book(socket, socket.assigns.live_action, book_params)
  end

  defp save_book(socket, :edit, book_params) do
    case Books.update_book(socket.assigns.book, socket.assigns.current_user, book_params) do
      {:ok, _book} ->
        {:noreply, push_navigate(socket, to: socket.assigns.back_to)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :changeset, changeset)}
    end

    # TODO Handle :unauthorized
    # TODO Don't allow getting on the page in the first place is not allowed
  end

  defp save_book(socket, :new, book_params) do
    case Books.create_book(book_params, socket.assigns.current_user) do
      {:ok, book} ->
        {:noreply, push_navigate(socket, to: ~p"/books/#{book}/transfers")}

      {:error, changeset} ->
        {:noreply, assign(socket, changeset: changeset)}
    end
  end
end
