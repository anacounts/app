defmodule Anacounts.Accounts.Balance do
  @moduledoc """
  Context to compute balance between book members.
  """

  alias Anacounts.Accounts
  alias Anacounts.Accounts.Balance.Graph
  alias Anacounts.Accounts.Balance.Means
  alias Anacounts.Transfers

  @type t :: %{
          members_balance: %{Accounts.BookMember.id() => Money.t()},
          transactions:
            list(%{
              from: Accounts.BookMember.id(),
              to: Accounts.BookMember.id(),
              amount: Money.t()
            })
        }

  @typedoc "The balance of a member for a transfer."
  @type peer_balance :: %{
          from: Accounts.BookMember.id(),
          to: Accounts.BookMember.id(),
          amount: Money.t(),
          transfer_id: Transfers.MoneyTransfer.id()
        }

  @spec for_book(Accounts.Book.id()) :: t()
  def for_book(book_id) do
    balance_graph = balance_graph(book_id)
    members_balance = members_balance(balance_graph)
    transactions = transactions(balance_graph)

    %{
      members_balance: members_balance,
      transactions: transactions
    }
  end

  defp balance_graph(book_id) do
    transfers = Transfers.find_transfers_in_book(book_id)

    transfers
    |> Enum.flat_map(&balance_transfer_by_peer/1)
    |> Graph.from_peer_balances()
  end

  defp balance_transfer_by_peer(transfer) do
    # means = Means.from_code(transfer.balance_means)
    means = Means.from_code(nil)
    means.balance_transfer_by_peer(transfer)
  end

  defp members_balance(balance_graph) do
    Graph.nodes_weight(balance_graph)
  end

  defp transactions(balance_graph) do
    balance_graph
    |> Graph.contract_vertices()
    |> Graph.vertices()
    |> Enum.map(&%{from: &1.from, to: &1.to, amount: &1.weight})
  end
end
