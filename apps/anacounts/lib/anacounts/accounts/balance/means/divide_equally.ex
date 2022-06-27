defmodule Anacounts.Accounts.Balance.Means.DivideEqually do
  @behaviour Anacounts.Accounts.Balance.Means

  alias Anacounts.Transfers
  alias Anacounts.Transfers.MoneyTransfer

  @impl Anacounts.Accounts.Balance.Means
  def balance_transfer_by_peer(money_transfer) do
    peers = Transfers.find_transfer_peers(money_transfer.id)

    transfer_amount = MoneyTransfer.amount(money_transfer)
    total_weight = Enum.reduce(peers, Decimal.new(0), &Decimal.add(&2, &1.weight))

    # FIXME e.g. total_amount = 15, with 2 peers, relative_weight = 0.5, then peer_amount = 8 twice
    # idea: use index, if index == (1 / relative_weight), do +/- 1
    # idea2: use `Money.divide/2`

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
  end
end
