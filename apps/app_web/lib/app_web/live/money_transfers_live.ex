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
      <% # Transfers summary %>
      <% # `details/summary` cannot be forced open on desktop, use the checkbox hack instead %>
      <div id="transfers-summary" class="md:w-80 mx-2 mb-4 p-2 border-b md:border-none border-gray-40">
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

      <% # Transfers list %>
      <div id="transfers-list" class="grow basis-3/4 max-w-prose mx-auto">
        <div class="md:hidden mx-2 text-right">
          <.button color={:ghost} phx-click={show_dialog("#filters")}>
            <.icon name="tune" />
          </.button>
        </div>

        <div
          id="money-transfers"
          phx-update="stream"
          phx-viewport-top={@page > 1 && "prev-page"}
          phx-viewport-bottom={!@end_of_timeline? && "next-page"}
          class={[
            if(@end_of_timeline?, do: "pb-10", else: "pb-[200vh]"),
            if(@page == 1, do: "pt-10", else: "pt-[calc(200vh)]")
          ]}
        >
          <.tile
            :for={{id, transfer} <- @streams.money_transfers}
            id={id}
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

      <% # Filters %>
      <.filters id="filters" phx-change="filter">
        <:section icon="arrow_downward" title={gettext("Sort by")}>
          <.filter_options field={@filters_form[:sort_by]} options={sort_by_options()} />
        </:section>

        <:section icon="filter_alt" title={gettext("Filter by")}>
          <.filter_options field={@filters_form[:tenanted_by]} options={tenanted_by_options()} />
        </:section>
      </.filters>
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

  @default_filters %{"sort_by" => "most_recent", "tenanted_by" => "anyone"}

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    book = socket.assigns.book

    filters_form = to_form(@default_filters, as: :filters)
    filters = filters_for_context(socket, @default_filters)

    socket =
      socket
      |> assign(
        page_title: gettext("Transfers · %{book_name}", book_name: book.name),
        # TODO remove
        layout_heading: gettext("Transfers"),
        # filters
        filters: filters,
        filters_form: filters_form,
        # pagination
        page: 1,
        per_page: 25
      )
      |> paginate_money_transfers(1)
      |> assign_amounts_summaries()

    {:ok, socket, layout: {AppWeb.Layouts, :book}, temporary_assigns: [filters_form: nil]}
  end

  defp reset_money_transfers(socket) do
    %{book: book, per_page: per_page, filters: filters} = socket.assigns

    money_transfers = list_transfers(book, 1, per_page, filters)

    socket
    |> assign(end_of_timeline?: Enum.empty?(money_transfers), page: 1)
    |> stream(:money_transfers, money_transfers, reset: true)
  end

  defp paginate_money_transfers(socket, new_page) when new_page >= 1 do
    %{book: book, per_page: per_page, page: cur_page, filters: filters} = socket.assigns

    money_transfers = list_transfers(book, new_page, per_page, filters)
    superior_page? = new_page >= cur_page

    {money_transfers, at, limit} =
      if superior_page? do
        {money_transfers, -1, per_page * 3 * -1}
      else
        {Enum.reverse(money_transfers), 0, per_page * 3}
      end

    if Enum.empty?(money_transfers) do
      socket
      |> assign(end_of_timeline?: superior_page?)
      # ensure the stream is at least initialized
      |> stream(:money_transfers, [])
    else
      socket
      |> assign(end_of_timeline?: false, page: new_page)
      |> stream(:money_transfers, money_transfers, at: at, limit: limit)
    end
  end

  defp list_transfers(book, page, per_page, filters) do
    book
    |> Transfers.list_transfers_of_book(
      offset: (page - 1) * per_page,
      limit: per_page,
      filters: filters
    )
    |> Transfers.with_tenant()
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

  defp sort_by_options do
    [
      {gettext("Most recent"), "most_recent"},
      {gettext("Oldest"), "oldest"},
      {gettext("Last created"), "last_created"},
      {gettext("First created"), "first_created"}
    ]
  end

  defp tenanted_by_options do
    [
      {gettext("Paid by anyone"), "anyone"},
      {gettext("Paid by me"), "me"},
      {gettext("Paid by others"), "others"}
    ]
  end

  @impl Phoenix.LiveView
  def handle_event("next-page", _params, socket) do
    {:noreply, paginate_money_transfers(socket, socket.assigns.page + 1)}
  end

  def handle_event("prev-page", %{"_overran" => true}, socket) do
    {:noreply, paginate_money_transfers(socket, 1)}
  end

  def handle_event("prev-page", _params, socket) do
    if socket.assigns.page > 1 do
      {:noreply, paginate_money_transfers(socket, socket.assigns.page - 1)}
    else
      {:noreply, socket}
    end
  end

  def handle_event("filter", %{"filters" => filters}, socket) do
    context_filters = filters_for_context(socket, filters)

    socket =
      socket
      |> assign(filters: context_filters, filters_form: to_form(filters, as: :filters))
      |> reset_money_transfers()

    {:noreply, socket}
  end

  def handle_event("delete", %{"id" => money_transfer_id}, socket) do
    book = socket.assigns.book

    money_transfer = Transfers.get_money_transfer_of_book!(money_transfer_id, book.id)

    {:ok, _} = Transfers.delete_money_transfer(money_transfer)

    socket =
      socket
      |> stream_delete(:money_transfers, money_transfer)
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

  defp filters_for_context(socket, filters) do
    current_member = socket.assigns.current_member

    Map.update(filters, "tenanted_by", :anyone, fn
      "anyone" -> :anyone
      "me" -> current_member.id
      "others" -> {:not, current_member.id}
    end)
  end
end
