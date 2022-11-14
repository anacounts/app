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

    members =
      Members.list_members_of_book(book)
      |> Balance.fill_members_balance()

    socket =
      socket
      |> assign(
        page_title: "Balance · #{book.name}",
        layout_heading: gettext("Balance"),
        book: book,
        members: members
      )
      |> assign_transactions()

    {:ok, socket, layout: {AppWeb.LayoutView, "book.html"}}
  end

  defp assign_transactions(socket) do
    case Balance.transactions(socket.assigns.members) do
      {:ok, transactions} ->
        assign(socket, transactions_error?: false, transactions: transactions)

      :error ->
        assign(socket, transactions_error?: true)
    end
  end

  defp transfer_icon_and_class_for_amount(amount) do
    cond do
      Money.zero?(amount) -> {"check", ""}
      Money.negative?(amount) -> {"remove", "text-error"}
      true -> {"add", "text-info"}
    end
  end
end
