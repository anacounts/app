defmodule App.Transfers.Peers do
  @moduledoc """
  Context for money transfer peers.
  """

  import Ecto.Query
  alias App.Repo

  alias App.Transfers.Peers.Peer

  @spec list_peers_of_transfer(MoneyTransfer.id()) :: [Peer.t()]
  def list_peers_of_transfer(transfer_id) do
    base_query()
    |> where_transfer_id(transfer_id)
    # TODO no preloading !
    |> preload(:member)
    |> Repo.all()
  end

  ## Queries

  def base_query do
    from Peer, as: :peer
  end

  def join_member(query) do
    with_named_binding(query, :book_member, fn query ->
      join(query, :inner, [peer: peer], assoc(peer, :member), as: :book_member)
    end)
  end

  def where_transfer_id(query, transfer_id) do
    from [peer: peer] in query,
      where: peer.transfer_id == ^transfer_id
  end
end
