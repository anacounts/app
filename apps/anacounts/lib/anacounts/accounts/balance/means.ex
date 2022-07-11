defmodule Anacounts.Accounts.Balance.Means do
  @moduledoc """
  A behavior to represents means to divide transfer amount between peers.
  """

  alias Anacounts.Accounts.Balance
  alias Anacounts.Accounts.Balance.Means
  alias Anacounts.Transfers.MoneyTransfer

  @doc """
  Divide the given money transfer between its associated peers.
  """
  @callback balance_transfer_by_peer(MoneyTransfer.t()) :: [Balance.peer_balance()]

  def from_code(_balance_means_code), do: Means.DivideEqually
end
