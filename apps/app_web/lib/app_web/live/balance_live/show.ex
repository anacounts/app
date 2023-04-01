defmodule AppWeb.BalanceLive.Show do
  @moduledoc """
  The balance show live view.
  Displays the balance of the members of a book.
  """

  use AppWeb, :live_view

  alias App.Balance
  alias App.Books.Members

  on_mount {AppWeb.BookAccess, :ensure_book!}

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    book = socket.assigns.book

    socket =
      socket
      |> assign(
        page_title: "Balance · #{book.name}",
        layout_heading: gettext("Balance")
      )
      |> assign_transactions()

    {:ok, socket, layout: {AppWeb.Layouts, :book}}
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
