defmodule AppWeb.BookBalanceLive do
  use AppWeb, :live_view

  import AppWeb.BooksComponents, only: [balance_card: 1]

  alias App.Balance
  alias App.Books.Book
  alias App.Books.Members

  on_mount {AppWeb.BookAccess, :ensure_book!}

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <.app_page>
      <:breadcrumb>
        <.breadcrumb_item navigate={~p"/books/#{@book}"}>
          <%= @book.name %>
        </.breadcrumb_item>
        <.breadcrumb_item>
          <%= @page_title %>
        </.breadcrumb_item>
      </:breadcrumb>
      <:title><%= @page_title %></:title>

      <.card_grid class="mb-4">
        <.balance_card book_member={@current_member} />
        <.link navigate={~p"/books/#{@book}"}>
          <.card_button icon={:credit_card}>
            <%= gettext("Manual reimbursement") %>
          </.card_button>
        </.link>
      </.card_grid>

      <%= if @transaction_errors != nil do %>
        <.alert kind={:error} class="mb-4">
          <%= gettext("Some information is missing to balance the book") %>
        </.alert>
        <section class="space-y-4">
          <.transaction_error_tile
            :for={transaction_error <- @transaction_errors}
            book={@book}
            {transaction_error}
          />
        </section>
      <% else %>
        <.tile>
          <div class="grid grid-rows-2 grid-cols-[1fr_9rem] items-center grid-flow-col grow">
            <div class="truncate">
              <span class="label text-theme-500">John Doe</span>
              owes <span class="label">Jane Doe</span>
            </div>
            <span class="label">330€</span>
            <.button kind={:ghost} class="row-span-2">
              Settle up <.icon name={:chevron_right} />
            </.button>
          </div>
        </.tile>
      <% end %>
    </.app_page>
    """
  end

  attr :book, Book, required: true
  attr :kind, :atom, required: true
  attr :extra, :map, required: true

  defp transaction_error_tile(%{kind: :revenues_missing} = assigns) do
    ~H"""
    <.link navigate={~p"/books/#{@book}/members/#{@extra.member}"} class="block">
      <.tile class="justify-between">
        <div class="truncate">
          <span class="label"><%= @extra.member.nickname %></span>
          <span class="font-normal">did not set their revenues.</span>
        </div>
        <.button kind={:ghost}>
          <%= gettext("Fix it") %> <.icon name={:chevron_right} />
        </.button>
      </.tile>
    </.link>
    """
  end

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    %{book: book, current_member: current_member} = socket.assigns

    members =
      book
      |> Members.list_members_of_book()
      |> Balance.fill_members_balance()

    current_member = Enum.find(members, &(&1.id == current_member.id))

    socket =
      socket
      |> assign(
        page_title: gettext("Balance"),
        current_member: current_member
      )
      |> assign_transactions(members)

    {:ok, socket, temporary_assigns: [transaction_errors: []]}
  end

  defp assign_transactions(socket, members) do
    case Balance.transactions(members) do
      {:ok, transactions} ->
        socket
        |> assign(transaction_errors: nil)
        |> stream(:transactions, transactions)

      {:error, reasons} ->
        assign(socket, transaction_errors: reasons)
    end
  end
end
