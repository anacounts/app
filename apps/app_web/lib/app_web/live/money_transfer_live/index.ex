defmodule AppWeb.MoneyTransferLive.Index do
  @moduledoc """
  The money transfer index live view.
  Shows money transfers for the current book.
  """

  use AppWeb, :live_view

  alias App.Transfers

  on_mount {AppWeb.BookAccess, :ensure_book!}

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

    {:ok, socket, layout: {AppWeb.LayoutView, "book.html"}}
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
