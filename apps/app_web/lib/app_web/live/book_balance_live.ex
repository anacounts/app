defmodule AppWeb.BookBalanceLive do
  use AppWeb, :live_view

  alias App.Balance
  alias App.Books

  alias AppWeb.BooksHelpers
  alias AppWeb.ReimbursementModalComponent

  on_mount {AppWeb.BookAccess, :ensure_book!}
  on_mount {AppWeb.BookAccess, :assign_book_members}
  on_mount {AppWeb.BookAccess, :assign_book_unbalanced}

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <section>
      <.heading level={:section} class="mt-4">
        <%= gettext("How to balance?") %>
      </.heading>
      <.list>
        <%= if @transactions_error? do %>
          <.list_item>
            <%= gettext("An error occured while balancing the transactions") %>
          </.list_item>
        <% else %>
          <%= if Enum.empty?(@transactions) do %>
            <.list_item>
              <%= gettext("The transactions are balanced already!") %>
            </.list_item>
          <% else %>
            <.list_item :for={transaction <- @transactions}>
              <div class="grow">
                <span class="font-bold">
                  <%= transaction.from.display_name %>
                </span>
                <span><%= gettext("gives") %></span>
                <span class="font-bold">
                  <%= transaction.to.display_name %>
                </span>
              </div>
              <%= transaction.amount %>
              <.button
                :if={not Books.closed?(@book)}
                color={:cta}
                phx-click={JS.push("select-transaction") |> show_dialog("#reimbursement-modal")}
                phx-value-transaction-id={transaction.id}
              >
                <%= gettext("Settle up") %>
              </.button>
            </.list_item>
          <% end %>
        <% end %>
      </.list>
      <.live_component
        module={ReimbursementModalComponent}
        id="reimbursement-modal"
        book={@book}
        open={@current_transaction != nil}
        transaction={@current_transaction}
      />
    </section>
    """
  end

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    book = socket.assigns.book

    socket =
      socket
      |> assign(
        page_title: "Balance · #{book.name}",
        current_transaction: nil
      )
      |> assign_transactions()

    {:ok, socket, layout: {AppWeb.Layouts, :book}}
  end

  defp assign_transactions(socket) do
    case Balance.transactions(socket.assigns.book_members) do
      {:ok, transactions} ->
        assign(socket, transactions_error?: false, transactions: transactions)

      :error ->
        assign(socket, transactions_error?: true)
    end
  end

  @impl Phoenix.LiveView
  def handle_event("delete-book", _params, socket) do
    BooksHelpers.handle_delete_book(socket)
  end

  def handle_event("close-book", _params, socket) do
    BooksHelpers.handle_close_book(socket)
  end

  def handle_event("reopen-book", _params, socket) do
    BooksHelpers.handle_reopen_book(socket)
  end

  def handle_event("select-transaction", %{"transaction-id" => transaction_id}, socket) do
    transaction = Enum.find(socket.assigns.transactions, &(&1.id == transaction_id))

    {:noreply, assign(socket, current_transaction: transaction)}
  end
end
