defmodule AppWeb.MoneyTransfersLive do
  @moduledoc """
  The money transfer index live view.
  Shows money transfers for the current book.
  """

  use AppWeb, :live_view

  alias App.Books
  alias App.Transfers

  alias AppWeb.BooksHelpers

  on_mount {AppWeb.BookAccess, :ensure_book!}
  on_mount {AppWeb.BookAccess, :assign_book_members}
  on_mount {AppWeb.BookAccess, :assign_book_unbalanced}

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <div class="md:flex md:justify-center">
      <% # `details/summary` cannot be forced open on desktop, use the checkbox hack instead %>
      <div class="md:w-80 mx-2 mb-4 p-2 border-b md:border-none border-gray-40">
        <label
          for="details-hack"
          class="mb-0 text-xl text-center list-none cursor-pointer md:cursor-default"
        >
          <.transfer_amount
            amount_class={class_for_amount(@total_summary.amount)}
            amount={@total_summary}
          />
        </label>

        <input id="details-hack" type="checkbox" class="peer hidden" />

        <div class="hidden md:block peer-checked:block mt-4">
          <.amounts_summary
            amounts_summary={@amounts_summary}
            payments_title={gettext("Payments")}
            incomes_title={gettext("Incomes")}
          />
          <hr class="my-2 border-gray-30" />
          <.amounts_summary
            amounts_summary={@your_amounts_summary}
            payments_title={gettext("Your payments")}
            incomes_title={gettext("Your incomes")}
          />
        </div>
      </div>

      <div class="grow basis-3/4 max-w-prose">
        <.tile
          :for={transfer <- @money_transfers}
          summary_class={["font-bold", class_for_transfer_type(transfer.type)]}
          collapse
        >
          <.icon name={icon_for_transfer_type(transfer.type)} />
          <span class="grow"><%= transfer.label %></span>
          <%= Money.to_string!(transfer.amount) %>

          <:description>
            <div class="flex justify-between mb-3">
              <div class="font-bold">
                <%= tenant_label_for_transfer_type(transfer.type, transfer.tenant.display_name) %>
              </div>
              <div>
                <time datetime={to_string(transfer.date)}><%= format_date(transfer.date) %></time>
                <.icon name="calendar-month" />
              </div>
            </div>
            <div :if={transfer.type != :reimbursement} class="text-right">
              <%= format_code(transfer.balance_params.means_code) %>
              <.icon name="swap-horiz" />
            </div>
          </:description>

          <:button
            :if={transfer.type != :reimbursement}
            navigate={~p"/books/#{@book}/transfers/#{transfer.id}/edit"}
          >
            <%= gettext("Edit") %>
          </:button>
          <:button
            class="text-error"
            data-confirm={gettext("Are you sure you want to delete the transfer?")}
            phx-click="delete"
            phx-value-id={transfer.id}
          >
            <%= gettext("Delete") %>
          </:button>
        </.tile>
      </div>
    </div>

    <.fab_container :if={not Books.closed?(@book)} class="mb-12 md:mb-0">
      <:item>
        <.fab navigate={~p"/books/#{@book}/transfers/new"}>
          <.icon name="add" alt="Add a money transfer" />
        </.fab>
      </:item>
    </.fab_container>
    """
  end

  attr :amounts_summary, :map, required: true
  attr :payments_title, :string, required: true
  attr :incomes_title, :string, required: true

  defp amounts_summary(assigns) do
    ~H"""
    <div><%= @payments_title %></div>
    <.transfer_amount amount_class="text-error" amount={@amounts_summary[:payment]} />

    <div><%= @incomes_title %></div>
    <.transfer_amount amount_class="text-info" amount={@amounts_summary[:income]} />
    """
  end

  attr :amount_class, :any, default: nil
  attr :amount, :map, required: true

  defp transfer_amount(assigns) do
    ~H"""
    <span class={["text-lg", @amount_class]}><%= Money.to_string!(@amount.amount) %></span>
    / <%= ngettext("%{count} transfer", "%{count} transfers", @amount.count) %>
    """
  end

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    book = socket.assigns.book

    money_transfers =
      book
      |> Transfers.list_transfers_of_book()
      |> Transfers.with_tenant()

    socket =
      assign(socket,
        page_title: gettext("Transfers · %{book_name}", book_name: book.name),
        layout_heading: gettext("Transfers"),
        money_transfers: money_transfers
      )
      |> assign_amounts_summaries()

    {:ok, socket, layout: {AppWeb.Layouts, :book}}
  end

  defp assign_amounts_summaries(socket) do
    %{book: book, current_member: current_member} = socket.assigns

    amounts_summary = Transfers.amounts_summary_for_book(book)
    your_amounts_summary = Transfers.amounts_summary_for_tenant(current_member)
    total_summary = total_summary(amounts_summary)

    assign(socket,
      total_summary: total_summary,
      amounts_summary: amounts_summary,
      your_amounts_summary: your_amounts_summary
    )
  end

  defp total_summary(%{income: total_incomes, payment: total_payments}) do
    %{
      amount: Money.sub!(total_incomes.amount, total_payments.amount),
      count: total_incomes.count + total_payments.count
    }
  end

  @impl Phoenix.LiveView
  def handle_event("delete", %{"id" => money_transfer_id}, socket) do
    book = socket.assigns.book

    money_transfer = Transfers.get_money_transfer_of_book!(money_transfer_id, book.id)

    {:ok, _} = Transfers.delete_money_transfer(money_transfer)

    socket =
      socket
      |> update(:money_transfers, fn money_transfers ->
        Enum.reject(money_transfers, &(&1.id == money_transfer.id))
      end)
      |> assign_amounts_summaries()

    {:noreply, socket}
  end

  def handle_event("delete-book", _params, socket) do
    BooksHelpers.handle_delete_book(socket)
  end

  def handle_event("close-book", _params, socket) do
    BooksHelpers.handle_close_book(socket)
  end

  def handle_event("reopen-book", _params, socket) do
    BooksHelpers.handle_reopen_book(socket)
  end

  defp class_for_transfer_type(:payment), do: "text-error"
  defp class_for_transfer_type(:income), do: "text-info"
  defp class_for_transfer_type(:reimbursement), do: nil

  defp class_for_amount(amount) do
    cond do
      Money.negative?(amount) -> "text-error"
      Money.positive?(amount) -> "text-info"
      true -> nil
    end
  end

  defp icon_for_transfer_type(:payment), do: "remove"
  defp icon_for_transfer_type(:income), do: "add"
  defp icon_for_transfer_type(:reimbursement), do: "arrow-forward"

  defp tenant_label_for_transfer_type(:payment, name), do: gettext("Paid by %{name}", name: name)

  defp tenant_label_for_transfer_type(:income, name),
    do: gettext("Received by %{name}", name: name)

  defp tenant_label_for_transfer_type(:reimbursement, name),
    do: gettext("Reimbursed to %{name}", name: name)

  defp format_code(:divide_equally), do: gettext("Divide equally")
  defp format_code(:weight_by_income), do: gettext("Weight by income")
end
