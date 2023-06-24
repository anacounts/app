defmodule AppWeb.ReimbursementModalComponent do
  @moduledoc """
  The reimbursement form live view.
  Create or update a reimbursement - a special form of money transfers - in a book.
  """

  use AppWeb, :live_component

  alias App.Books.Members

  @impl Phoenix.LiveComponent
  def render(assigns) do
    ~H"""
    <div class="contents">
      <.form
        for={@form}
        id="reimbursement-form"
        phx-change="validate"
        phx-submit="submit"
        phx-target={@myself}
      >
        <.modal id={@id} open={@open} dismiss={false}>
          <:header>
            <.icon name="arrow-forward" />
            <%= gettext("New Reimbursement") %>

            <.button
              color={:ghost}
              type="button"
              class="modal__dismiss"
              phx-click="reimbursement-modal/close"
              aria-label={gettext("Close")}
            >
              <.icon name="close" />
            </.button>
          </:header>

          <div class="grid grid-cols-2 gap-x-4">
            <.input
              field={@form[:label]}
              type="text"
              label={gettext("Label")}
              label_class="col-span-2"
              class="w-full"
              required
            />

            <.input
              field={@form[:creditor_id]}
              type="select"
              options={@member_options}
              label={gettext("Received by")}
              class="w-full"
              required
            />
            <.input
              field={@form[:amount]}
              type="money"
              label={gettext("Amount")}
              class="w-full"
              required
            />

            <.input
              field={@form[:debtor_id]}
              type="select"
              options={@member_options}
              label={gettext("Paid by")}
              class="w-full"
              required
            />
            <.input field={@form[:date]} type="date" label={gettext("Date")} class="w-full" required />
          </div>

          <:footer>
            <.button color={:feature} type="button" phx-click="reimbursement-modal/close">
              <%= gettext("Cancel") %>
            </.button>
            <.button color={:cta}>
              <%= gettext("Save") %>
            </.button>
          </:footer>
        </.modal>
      </.form>
    </div>
    """
  end

  @impl Phoenix.LiveComponent
  def mount(socket) do
    {:ok, socket, temporary_assigns: [member_options: []]}
  end

  @impl Phoenix.LiveComponent
  def update(assigns, socket) do
    {:ok,
     socket
     |> assign_member_options(assigns[:book])
     |> assign_form(assigns)
     |> assign(assigns)}
  end

  defp assign_member_options(socket, book) do
    member_options = member_options_of_book(book)
    assign(socket, member_options: member_options)
  end

  defp member_options_of_book(nil), do: []

  defp member_options_of_book(book) do
    book
    |> Members.list_members_of_book()
    |> Enum.map(&{&1.display_name, &1.id})
  end

  defp assign_form(socket, assigns) do
    transaction = assigns[:transaction] || socket.assigns[:transaction]

    form =
      if transaction,
        do:
          to_form(%{
            "label" => new_transfer_label(transaction.to, transaction.from),
            "creditor_id" => transaction.to.id,
            "amount" => transaction.amount,
            "debtor_id" => transaction.from.id,
            "date" => Date.utc_today()
          }),
        else: to_form(%{})

    assign(socket, form: form)
  end

  defp new_transfer_label(creditor, debtor) do
    if debtor && creditor do
      gettext("Reimbursement from %{debtor_name} to %{creditor_name}",
        debtor_name: debtor.display_name,
        creditor_name: creditor.display_name
      )
    end
  end

  @impl Phoenix.LiveComponent
  def handle_event("validate", params, socket) do
    # TODO validate form
    {:noreply, socket}
  end

  def handle_event("submit", params, socket) do
    # TODO submit form
    {:noreply, socket}
  end
end
