defmodule AppWeb.BalanceLive.Show do
  @moduledoc """
  The balance show live view.
  Displays the balance of the members of a book.
  """

  use AppWeb, :live_view

  alias App.Balance
  alias App.Books
  alias App.Books.Members

  @impl Phoenix.LiveView
  def mount(%{"book_id" => book_id}, _session, socket) do
    book = Books.get_book_of_user!(book_id, socket.assigns.current_user)

    socket =
      socket
      |> assign(
        page_title: "Balance · #{book.name}",
        layout_heading: gettext("Balance"),
        book: book
      )
      |> assign_transactions()

    {:ok, socket, layout: {AppWeb.LayoutView, "book.html"}}
  end

  defp assign_transactions(socket) do
    members =
      Members.list_members_of_book(socket.assigns.book)
      |> Balance.fill_members_balance()

    case Balance.transactions(members) do
      {:ok, transactions} ->
        assign(socket, transactions_error?: false, transactions: transactions)

      :error ->
        assign(socket, transactions_error?: true)
    end
  end
end
