defmodule AppWeb.MoneyTransferLive.Index do
  @moduledoc """
  The money transfer index live view.
  Shows money transfers for the current book.
  """

  use AppWeb, :live_view

  alias App.Books
  alias App.Transfers

  @impl Phoenix.LiveView
  def mount(%{"book_id" => book_id}, _session, socket) do
    book = Books.get_book_of_user!(book_id, socket.assigns.current_user)

    money_transfers =
      book_id
      |> Transfers.find_transfers_in_book()
      # TODO No preload here
      |> App.Repo.preload(tenant: :user)

    socket =
      assign(socket,
        page_title: gettext("Transfers · %{book_name}", book_name: book.name),
        layout_heading: gettext("Transfers"),
        book: book,
        money_transfers: money_transfers
      )

    {:ok, socket, layout: {AppWeb.LayoutView, "book.html"}}
  end

  defp icon_and_class_for_transfer_type(:payment), do: {"minus", "text-error"}
  defp icon_and_class_for_transfer_type(:income), do: {"plus", "text-success"}
  defp icon_and_class_for_transfer_type(:reimbursement), do: {"arrow-right", ""}
end
