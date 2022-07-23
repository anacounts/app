defmodule AppWeb.BalanceLive.Show do
  @moduledoc """
  The balance show live view.
  Displays the balance of the members of a book.
  """

  use AppWeb, :live_view

  alias App.Accounts
  alias App.Accounts.Balance

  @impl Phoenix.LiveView
  def mount(%{"book_id" => book_id}, _session, socket) do
    book = Accounts.get_book_of_user!(book_id, socket.assigns.current_user)

    %{members_balance: members_balance, transactions: transactions} = Balance.for_book(book_id)

    socket =
      assign(socket,
        book: book,
        members_balance: members_balance,
        transactions: transactions
      )

    {:ok, socket, layout: {AppWeb.LayoutView, "book.html"}}
  end

  @impl Phoenix.LiveView
  def handle_params(_params, _url, socket) do
    {:noreply, assign(socket, :page_title, gettext("Balance"))}
  end

  defp transfer_icon_and_class_for_amount(amount) do
    cond do
      Money.zero?(amount) -> {"check", ""}
      Money.negative?(amount) -> {"minus", "text-error"}
      true -> {"plus", "text-success"}
    end
  end
end
