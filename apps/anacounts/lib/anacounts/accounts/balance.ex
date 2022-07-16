# Disable checking that there are too many dependencies
# See comments below, this module needs to be refactored
# credo:disable-for-this-file Credo.Check.Refactor.ModuleDependencies
defmodule Anacounts.Accounts.Balance do
  @moduledoc """
  Context to compute balance between book members.
  """

  alias Anacounts.Accounts
  alias Anacounts.Accounts.Balance.Graph
  alias Anacounts.Accounts.Balance.Means
  alias Anacounts.Accounts.Balance.UserParams
  alias Anacounts.Auth.User
  alias Anacounts.Transfers

  alias Anacounts.Repo

  # TODO This should move to another specialized module.
  # This is going to be the main context for the `balance` module,
  # so specialized operation like these shouldn't appear here
  # (or maybe just the `for_book/1` function, I don't know yet)

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

  # --- Actual module content ---

  @spec find_user_params(User.id()) :: [UserParams.t()]
  def find_user_params(user_id) do
    UserParams.base_query()
    |> UserParams.where_user_id(user_id)
    |> Repo.all()
  end

  @spec get_user_params_with_code(User.id(), Means.code()) :: UserParams.t() | nil
  def get_user_params_with_code(user_id, means_code) do
    UserParams.base_query()
    |> UserParams.where_user_id(user_id)
    |> UserParams.where_means_code(means_code)
    |> Repo.one()
  end

  @spec upsert_user_params(map()) :: {:ok, UserParams.t()} | {:error, Ecto.Changeset.t()}
  def upsert_user_params(attrs) do
    UserParams.changeset(attrs)
    |> Repo.insert(
      conflict_target: [:user_id, :means_code],
      on_conflict: {:replace, [:params]}
    )
  end

  @spec delete_user_params(UserParams.t()) :: {:ok, UserParams.t()} | {:error, Ecto.Changeset.t()}
  def delete_user_params(user_params) do
    Repo.delete(user_params)
  end
end
