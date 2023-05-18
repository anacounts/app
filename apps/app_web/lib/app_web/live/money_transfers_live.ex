defmodule AppWeb.MoneyTransfersLive do
  @moduledoc """
  The money transfer index live view.
  Shows money transfers for the current book.
  """

  use AppWeb, :live_view

  alias App.Books.Rights
  alias App.Transfers

  on_mount {AppWeb.BookAccess, :ensure_book!}

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <div class="max-w-prose mx-auto">
      <.tile
        :for={transfer <- @money_transfers}
        class={["font-bold", class_for_transfer_type(transfer.type)]}
        collapse
      >
        <.icon name={icon_for_transfer_type(transfer.type)} />
        <span class="grow"><%= transfer.label %></span>
        <%= Money.to_string(transfer.amount) %>

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
          <div class="text-right">
            <%= format_code(transfer.balance_params.means_code) %>
            <.icon name="swap-horiz" />
          </div>
        </:description>

        <:button
          :if={Rights.can_member_handle_money_transfers?(@current_member)}
          navigate={~p"/books/#{@book}/transfers/#{transfer.id}/edit"}
        >
          <%= gettext("Edit") %>
        </:button>
        <:button
          :if={Rights.can_member_handle_money_transfers?(@current_member)}
          class="text-error"
          data-confirm={gettext("Are you sure you want to delete the transfer?")}
          phx-click="delete"
          phx-value-id={transfer.id}
        >
          <%= gettext("Delete") %>
        </:button>
      </.tile>
    </div>

    <.fab_container class="mb-12 md:mb-0">
      <:item :if={Rights.can_member_handle_money_transfers?(@current_member)}>
        <.fab navigate={~p"/books/#{@book}/transfers/new"}>
          <.icon name="add" alt="Add a money transfer" />
        </.fab>
      </:item>
    </.fab_container>
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

    {:ok, socket, layout: {AppWeb.Layouts, :book}}
  end

  @impl Phoenix.LiveView
  def handle_event("delete", %{"id" => money_transfer_id}, socket) do
    %{book: book, current_user: current_user} = socket.assigns

    money_transfer = Transfers.get_money_transfer_of_book!(money_transfer_id, book.id)

    {:ok, _} = Transfers.delete_money_transfer(money_transfer, current_user)

    {:noreply,
     update(socket, :money_transfers, fn money_transfers ->
       Enum.reject(money_transfers, &(&1.id == money_transfer.id))
     end)}
  end

  defp class_for_transfer_type(:payment), do: "text-error"
  defp class_for_transfer_type(:income), do: "text-info"
  defp class_for_transfer_type(:reimbursement), do: nil

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
