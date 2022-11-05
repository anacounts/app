defmodule AppWeb.MoneyTransferLive.Form do
  @moduledoc """
  The money transfer form live view.
  Create or update a money transfer for the current book.
  """

  use AppWeb, :live_view

  alias App.Auth.Avatars
  alias App.Books
  alias App.Books.Members
  alias App.Transfers
  alias App.Transfers.MoneyTransfer
  alias App.Transfers.Peers.Peer

  @impl Phoenix.LiveView
  def mount(%{"book_id" => book_id} = params, _session, socket) do
    book = Books.get_book_of_user!(book_id, socket.assigns.current_user)
    members = Members.list_members_of_book(book)

    socket = assign(socket, book: book, members: members)

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
     |> push_navigate(to: Routes.money_transfer_index_path(socket, :index, socket.assigns.book))}
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
         |> push_navigate(
           to: Routes.money_transfer_index_path(socket, :index, socket.assigns.book)
         )}

      {:error, %Ecto.Changeset{} = changeset} ->
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
         |> push_navigate(to: Routes.money_transfer_index_path(socket, :index, book))}

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
