defmodule App.Balance.Means.DivideEqually do
  @moduledoc """
  Implements `App.Balance.Means` behaviour.

  Divides money transfer amount equally among the peers.
  """

  @behaviour App.Balance.Means

  alias App.Transfers
  alias App.Transfers.Peers

  @impl App.Balance.Means
  def balance_transfer_by_peer(money_transfer) do
    peers = Peers.list_peers_of_transfer(money_transfer.id)

    transfer_amount = Transfers.amount(money_transfer)
    total_weight = Enum.reduce(peers, Decimal.new(0), &Decimal.add(&2, &1.weight))

    # FIXME e.g. total_amount = 15, with 2 peers, relative_weight = 0.5, then peer_amount = 8 twice
    # idea: use index, if index == (1 / relative_weight), do +/- 1
    # idea2: use `Money.divide/2`

    peers_balance =
      Enum.map(peers, fn peer ->
        relative_weight = Decimal.div(peer.weight, total_weight)
        peer_amount = Money.multiply(transfer_amount, relative_weight)

        %{
          from: peer.member_id,
          to: money_transfer.tenant_id,
          amount: peer_amount,
          transfer_id: money_transfer.id
        }
      end)

    {:ok, peers_balance}
  end
end
