defmodule AppWeb.ReimbursementModalComponent do
  @moduledoc """
  The reimbursement form live view.
  Create or update a reimbursement - a special form of money transfers - in a book.
  """

  use AppWeb, :live_component

  alias App.Books.Members
  alias App.Transfers
  alias App.Transfers.MoneyTransfer

  @impl Phoenix.LiveComponent
  def render(assigns) do
    ~H"""
    <div class="contents">
      <.popup id={@id} open={@open}>
        <:label><%= gettext("Balance") %></:label>
        <:title><%= gettext("New reimbursement") %></:title>

        <.form
          for={@form}
          id="reimbursement-form"
          phx-change="validate"
          phx-submit="submit"
          phx-target={@myself}
        >
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
        </.form>

        <:footer>
          <.button color={:ghost} type="button" phx-click={hide_dialog("##{@id}")}>
            <%= gettext("Cancel") %>
          </.button>
          <.button color={:cta} form="reimbursement-form">
            <%= gettext("Save") %>
          </.button>
        </:footer>
      </.popup>
    </div>
    """
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
    |> Enum.map(&{&1.nickname, &1.id})
  end

  defp assign_form(socket, assigns) do
    transaction = assigns[:transaction] || socket.assigns[:transaction]

    form =
      if transaction do
        to_form(
          %{
            "label" => new_transfer_label(transaction.to, transaction.from),
            "creditor_id" => transaction.to.id,
            "amount" => transaction.amount,
            "debtor_id" => transaction.from.id,
            "date" => Date.utc_today()
          },
          as: "reimbursement"
        )
      else
        to_form(%{}, as: "reimbursement")
      end

    assign(socket, :form, form)
  end

  defp new_transfer_label(creditor, debtor) do
    gettext("Reimbursement from %{debtor_name} to %{creditor_name}",
      debtor_name: debtor.nickname,
      creditor_name: creditor.nickname
    )
  end

  @impl Phoenix.LiveComponent
  def handle_event("validate", %{"reimbursement" => reimbursement_params}, socket) do
    money_transfer_params = money_transfer_params(reimbursement_params)

    form =
      %MoneyTransfer{}
      |> Transfers.change_money_transfer(money_transfer_params)
      |> to_reimbursement_form()

    {:noreply, assign(socket, :form, form)}
  end

  def handle_event("submit", %{"reimbursement" => reimbursement_params}, socket) do
    money_transfer_params = money_transfer_params(reimbursement_params)

    case Transfers.create_money_transfer(socket.assigns.book, money_transfer_params) do
      {:ok, _money_transfer} ->
        {:noreply,
         socket
         |> put_flash(:info, gettext("Reimbursement created successfully"))
         |> push_navigate(to: ~p"/books/#{socket.assigns.book}/transfers")}

      {:error, changeset} ->
        {:noreply, assign(socket, :form, to_reimbursement_form(changeset))}
    end
  end

  defp money_transfer_params(params) do
    {amount, params} = Map.pop(params, "amount")

    %{
      type: :reimbursement,
      balance_params: %{means_code: :divide_equally},
      label: params["label"],
      amount: parse_money_or_nil(amount),
      date: params["date"],
      tenant_id: params["creditor_id"],
      peers: [%{member_id: params["debtor_id"]}]
    }
  end

  defp parse_money_or_nil(""), do: nil
  defp parse_money_or_nil(amount), do: Money.new!(:EUR, amount)

  defp to_reimbursement_form(changeset) do
    changeset
    |> to_form(as: "reimbursement")
    |> Map.update!(:params, fn params ->
      {tenant_id, params} = Map.pop(params, "tenant_id")
      params = Map.put(params, "creditor_id", tenant_id)

      {[peer], params} = Map.pop(params, "peers")
      Map.put(params, "debtor_id", peer.member_id)
    end)
  end
end
