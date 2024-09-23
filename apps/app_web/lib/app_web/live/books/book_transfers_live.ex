defmodule AppWeb.BookTransfersLive do
  @moduledoc """
  The money transfer index live view.
  Shows money transfers for the current book.
  """

  use AppWeb, :live_view

  import Ecto.Query
  import AppWeb.TransfersComponents, only: [transfer_details: 1]

  alias App.Books.BookMember
  alias App.Repo
  alias App.Transfers
  alias App.Transfers.Peer

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

      <.link navigate={~p"/books/#{@book}/transfers/new"}>
        <.tile kind={:primary} class="mb-4">
          <.icon name={:plus} />
          <%= gettext("New transfer") %>
        </.tile>
      </.link>
      <div
        id="transfers"
        phx-update="stream"
        phx-viewport-top={@page > 1 && "prev-page"}
        phx-viewport-bottom={!@end_of_timeline? && "next-page"}
        class={[
          "space-y-4",
          if(@end_of_timeline?, do: "pb-10", else: "pb-[200vh]"),
          if(@page > 1, do: "pt-[200vh]")
        ]}
      >
        <.transfer_details
          :for={{dom_id, transfer} <- @streams.transfers}
          id={dom_id}
          transfer={transfer}
        >
          <:extra>
            <.divider />
            <div class="grid grid-cols-2 gap-2">
              <.button
                :if={transfer.type != :reimbursement}
                kind={:secondary}
                navigate={~p"/books/#{@book}/transfers/#{transfer}/edit"}
              >
                <.icon name={:pencil} />
                <%= gettext("Edit") %>
              </.button>
              <.button
                kind={:secondary}
                phx-click="delete"
                phx-value-id={transfer.id}
                data-confirm={gettext("Are you sure you want to delete the transfer?")}
              >
                <.icon name={:trash} />
                <%= gettext("Delete") %>
              </.button>
            </div>
          </:extra>
        </.transfer_details>
      </div>
    </.app_page>
    """
  end

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(
        page_title: gettext("Transfers"),
        # pagination
        page: 1,
        per_page: 25
      )
      |> paginate_transfers(1)

    {:ok, socket, temporary_assigns: [page_title: nil]}
  end

  defp paginate_transfers(socket, new_page) when new_page >= 1 do
    %{book: book, per_page: per_page, page: cur_page} = socket.assigns

    transfers = list_transfers(book, new_page, per_page)
    superior_page? = new_page >= cur_page

    {transfers, at, limit} =
      if superior_page? do
        {transfers, -1, per_page * 3 * -1}
      else
        {Enum.reverse(transfers), 0, per_page * 3}
      end

    if Enum.empty?(transfers) do
      socket
      |> assign(end_of_timeline?: superior_page?)
      # ensure the stream is at least initialized
      |> stream(:transfers, [])
    else
      socket
      |> assign(end_of_timeline?: false, page: new_page)
      |> stream(:transfers, transfers, at: at, limit: limit)
    end
  end

  defp list_transfers(book, page, per_page) do
    book
    |> Transfers.list_transfers_of_book(
      offset: (page - 1) * per_page,
      limit: per_page
    )
    # TODO optimize preload, the peers are only necessary for reimbursement transfers
    |> Repo.preload(
      tenant: BookMember.base_query(),
      peers:
        Peer.base_query()
        |> select([:id, :member_id])
        |> preload(member: ^(BookMember.base_query() |> select([:nickname])))
    )
  end

  @impl Phoenix.LiveView
  def handle_event("next-page", _params, socket) do
    {:noreply, paginate_transfers(socket, socket.assigns.page + 1)}
  end

  def handle_event("prev-page", %{"_overran" => true}, socket) do
    {:noreply, paginate_transfers(socket, 1)}
  end

  def handle_event("prev-page", _params, socket) do
    if socket.assigns.page > 1 do
      {:noreply, paginate_transfers(socket, socket.assigns.page - 1)}
    else
      {:noreply, socket}
    end
  end

  def handle_event("delete", %{"id" => money_transfer_id}, socket) do
    book = socket.assigns.book

    money_transfer = Transfers.get_money_transfer_of_book!(money_transfer_id, book.id)

    {:ok, _} = Transfers.delete_money_transfer(money_transfer)

    socket = stream_delete(socket, :transfers, money_transfer)

    {:noreply, socket}
  end
end
