defmodule AppWeb.BookBalanceLive do
  use AppWeb, :live_view

  alias App.Balance
  alias App.Books.Members

  on_mount {AppWeb.BookAccess, :ensure_book!}

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
            </.list_item>
          <% end %>
        <% end %>
      </.list>
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
