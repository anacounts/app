defmodule AppWeb.MoneyTransferFormLive do
  @moduledoc """
  The money transfer form live view.
  Create or update a money transfer for the current book.
  """

  use AppWeb, :live_view

  alias App.Accounts.Avatars
  alias App.Books.Members
  alias App.Transfers
  alias App.Transfers.MoneyTransfer
  alias App.Transfers.Peer

  on_mount {AppWeb.BookAccess, :ensure_book!}

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <.page_header back_to={~p"/books/#{@book}/transfers"}>
      <:title>
        <%= if @live_action == :new,
          do: gettext("New Transfer"),
          else: gettext("Edit Transfer") %>
      </:title>
      <:menu :if={@live_action == :edit}>
        <.dropdown id="contextual-menu">
          <:toggle>
            <.icon name="more-vert" alt={gettext("Contextual menu")} size={:lg} />
          </:toggle>

          <%= if @live_action == :edit do %>
            <.list_item_link id="delete-money-transfer" class="text-error" phx-click="delete">
              <.icon name="delete" />
              <%= gettext("Delete") %>
            </.list_item_link>
          <% end %>
        </.dropdown>
      </:menu>
    </.page_header>

    <main>
      <.form
        :let={f}
        for={@changeset}
        id="money-transfer-form"
        phx-change="validate"
        phx-submit="save"
      >
        <% ## Details %>
        <div class="mx-4">
          <.input type="text" label={gettext("Label")} field={f[:label]} pattern=".{1,255}" required />

          <div class="flex items-baseline gap-4">
            <% # XXX When supporting other currencies, the "/ 100" and step must be different based on currency %>
            <% amount =
              case Ecto.Changeset.get_field(@changeset, :amount, Money.new(0, :EUR)) do
                %{amount: amount} -> amount / 100
                nil -> nil
              end %>
            <.input
              type="number"
              label={gettext("Amount")}
              field={f[:amount]}
              value={amount}
              step="0.01"
              min="0"
              required
            />
            <.input
              type="select"
              label={gettext("Currency")}
              field={f[:currency]}
              options={currencies_options()}
              disabled
            />
          </div>

          <.input
            type="select"
            label={gettext("Type")}
            field={f[:type]}
            options={type_options()}
            required
          />
          <.input
            type="select"
            label={gettext("Tenant")}
            field={f[:tenant_id]}
            options={tenant_id_options(@members)}
            required
          />

          <% means_code =
            case Ecto.Changeset.get_field(@changeset, :balance_params) do
              %{means_code: means_code} -> means_code
              nil -> nil
            end %>

          <.input
            type="select"
            label={gettext("How to balance?")}
            field={f[:balance_means_code]}
            options={balance_params_options()}
            value={means_code}
            required
          />
          <% # TODO <button>More information</button> %>

          <.input type="date" label={gettext("Date")} field={f[:date]} required />
        </div>

        <hr class="my-4" />

        <% ## Peer list %>
        <.heading level={:section} class="flex justify-between">
          <% # TODO Add "select all" checkbox %> Members <span>Weight</span>
        </.heading>

        <.list>
          <% peers = Ecto.Changeset.get_field(@changeset, :peers) %>

          <%= for {member, index} <- Enum.with_index(@members) do %>
            <% peer = Enum.find(peers, &(&1.member_id == member.id)) %>

            <.list_item class="py-2">
              <input
                type="hidden"
                name={"money_transfer[peers][#{index}][id]"}
                value={if peer, do: peer.id, else: nil}
              />

              <input
                type="hidden"
                name={"money_transfer[peers][#{index}][member_id]"}
                value={member.id}
              />

              <label class="contents" for={"book-form_peers_#{index}_checked"}>
                <input type="hidden" name={"money_transfer[peers][#{index}][checked]"} value="false" />
                <input
                  type="checkbox"
                  id={"book-form_peers_#{index}_checked"}
                  name={"money_transfer[peers][#{index}][checked]"}
                  value="true"
                  checked={peer != nil}
                />
                <.avatar src={Avatars.avatar_url(member)} alt="" />
                <div class="grow">
                  <%= member.display_name %>
                </div>
                <input
                  type="number"
                  class="flex-1 w-full"
                  id={"book-form_peers_#{index}_weight"}
                  name={"money_transfer[peers][#{index}][weight]"}
                  step="0.01"
                  value={if peer, do: peer.weight, else: 1}
                  disabled={peer == nil}
                />
              </label>
            </.list_item>
          <% end %>
        </.list>

        <div class="mx-4 mb-4">
          <.button color={:cta} phx-disable-with={gettext("Saving...")}>
            <%= gettext("Save") %>
          </.button>
        </div>
      </.form>
    </main>
    """
  end

  @impl Phoenix.LiveView
  def mount(params, _session, socket) do
    book = socket.assigns.book
    members = Members.list_members_of_book(book)

    socket = assign(socket, members: members)

    {:ok, mount_action(socket, socket.assigns.live_action, params)}
  end

  defp mount_action(socket, :new, _params) do
    peers =
      socket.assigns.members
      |> Enum.with_index()
      |> Enum.map(fn {member, index} -> %Peer{id: index, member_id: member.id, member: member} end)

    money_transfer = %MoneyTransfer{date: Date.utc_today(), peers: peers}

    assign(socket,
      page_title: gettext("New Transfer"),
      money_transfer: money_transfer,
      changeset: Transfers.change_money_transfer(money_transfer)
    )
  end

  defp mount_action(socket, :edit, %{"money_transfer_id" => money_transfer_id}) do
    book = socket.assigns.book

    money_transfer =
      Transfers.get_money_transfer_of_book!(money_transfer_id, book.id)
      # TODO No preload here
      |> App.Repo.preload(:peers)

    assign(socket,
      page_title:
        gettext("%{transfer_name} · %{book_name}",
          transfer_name: money_transfer.label,
          book_name: book.name
        ),
      money_transfer: money_transfer,
      changeset: Transfers.change_money_transfer(money_transfer)
    )
  end

  @impl Phoenix.LiveView
  def handle_event("validate", %{"money_transfer" => money_transfer_params}, socket) do
    normalized_params = normalize_params(money_transfer_params)

    changeset =
      socket.assigns.money_transfer
      |> Transfers.change_money_transfer(normalized_params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, :changeset, changeset)}
  end

  def handle_event("save", %{"money_transfer" => money_transfer_params}, socket) do
    normalized_params = normalize_params(money_transfer_params)

    save_money_transfer(socket, socket.assigns.live_action, normalized_params)
  end

  def handle_event("delete", _params, socket) do
    money_transfer = socket.assigns.money_transfer
    user = socket.assigns.current_user
    {:ok, _} = Transfers.delete_money_transfer(money_transfer, user)

    {:noreply,
     socket
     |> put_flash(:info, gettext("Transfer deleted successfully"))
     |> push_navigate(to: ~p"/books/#{socket.assigns.book}/transfers")}
  end

  defp normalize_params(params) do
    # amount
    {amount, params} = Map.pop(params, "amount")
    {currency, params} = Map.pop(params, "currency", "EUR")

    params = Map.put(params, "amount", parse_money_or_nil(amount, currency))

    # balance params
    {balance_means_code, params} = Map.pop(params, "balance_means_code")

    params =
      Map.put(params, "balance_params", %{"means_code" => balance_means_code, "params" => nil})

    # peers
    Map.update(params, "peers", [], fn peers ->
      Map.filter(peers, fn {_key, peer} -> peer["checked"] == "true" end)
    end)
  end

  defp parse_money_or_nil(amount, currency) do
    case Money.parse(amount, currency) do
      {:ok, money} -> money
      :error -> nil
    end
  end

  defp save_money_transfer(socket, :new, money_transfer_params) do
    case Transfers.create_money_transfer(socket.assigns.book, money_transfer_params) do
      {:ok, _money_transfer} ->
        {:noreply,
         socket
         |> put_flash(:info, gettext("Money transfer created successfully"))
         |> push_navigate(to: ~p"/books/#{socket.assigns.book}/transfers")}

      {:error, changeset} ->
        {:noreply, assign(socket, changeset: changeset)}
    end
  end

  defp save_money_transfer(socket, :edit, money_transfer_params) do
    %{book: book, current_user: user, money_transfer: money_transfer} = socket.assigns

    # TODO Don't even allow to change the transfer if the user is not allowed
    case Transfers.update_money_transfer(money_transfer, user, money_transfer_params) do
      {:ok, _money_transfer} ->
        {:noreply,
         socket
         |> put_flash(:info, gettext("Money transfer updated successfully"))
         |> push_navigate(to: ~p"/books/#{book}/transfers")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :changeset, changeset)}
    end
  end

  defp currencies_options do
    [[key: "€", value: "EUR"]]
  end

  defp type_options do
    [
      [key: gettext("Payment"), value: "payment"],
      [key: gettext("Income"), value: "income"],
      [key: gettext("Reimbursement"), value: "reimbursement"]
    ]
  end

  defp tenant_id_options(book_members) do
    book_members
    |> Enum.sort_by(& &1.display_name)
    |> Enum.map(&[key: &1.display_name || "", value: &1.id])
  end

  defp balance_params_options do
    [
      [key: gettext("Divide equally"), value: "divide_equally"],
      [key: gettext("Weight by income"), value: "weight_by_income"]
    ]
  end
end
