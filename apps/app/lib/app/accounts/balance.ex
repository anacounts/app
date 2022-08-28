# Disable checking that there are too many dependencies
# See comments below, this module needs to be refactored
# credo:disable-for-this-file Credo.Check.Refactor.ModuleDependencies
defmodule App.Accounts.Balance do
  @moduledoc """
  Context to compute balance between book members.
  """

  alias App.Accounts.BookMember
  alias App.Accounts.Balance.Graph
  alias App.Accounts.Balance.Means
  alias App.Accounts.Balance.UserParams
  alias App.Auth.User
  alias App.Books.Book
  alias App.Transfers

  alias App.Repo

  # TODO This should move to another specialized module.
  # This is going to be the main context for the `balance` module,
  # so specialized operation like these shouldn't appear here
  # (or maybe just the `for_book/1` function, I don't know yet)

  @type t :: %{
          members_balance: %{BookMember.id() => Money.t()},
          transactions:
            list(%{
              from: BookMember.id(),
              to: BookMember.id(),
              amount: Money.t()
            })
        }

  @typedoc "The balance of a member for a transfer."
  @type peer_balance :: %{
          from: BookMember.id(),
          to: BookMember.id(),
          amount: Money.t(),
          transfer_id: Transfers.MoneyTransfer.id()
        }

  @spec for_book(Book.id()) :: t()
  def for_book(book_id) do
    balance_graph = balance_graph(book_id)
    members_balance = members_balance(balance_graph)
    transactions = transactions(members_balance)

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
    case Means.balance_transfer_by_peer(transfer) do
      {:ok, peer_balances} ->
        peer_balances

      # TODO handle this properly
      {:error, reason} ->
        raise "Could not balance transfer##{transfer.id}, reason: #{inspect(reason)}"
    end
  end

  defp members_balance(balance_graph) do
    Graph.nodes_weight(balance_graph)
  end

  defp transactions(members_balance) do
    {debtors, creditors} =
      Enum.split_with(members_balance, fn {_member_id, amount} -> Money.negative?(amount) end)

    make_transactions(debtors, creditors, [])
  end

  # Creates necessary transactions between creditors and debitors
  # to balance things. The total sum of creditors and debitors should be
  # equal to 0, or the function will crash.
  defp make_transactions(creditors, debitors, transactions)
  defp make_transactions([], [], transactions), do: transactions

  defp make_transactions(
         [{_debtor, neg_debt} | _other_debtors] = all_debtors,
         [{_creditor, credit} | _other_creditors] = all_creditors,
         transactions
       ) do
    debt = Money.neg(neg_debt)

    Money.cmp(credit, debt)
    |> add_transaction_from_cmp(all_debtors, all_creditors, transactions)
  end

  defp add_transaction_from_cmp(
         :eq,
         [{debtor, neg_debt} | other_debtors],
         [{creditor, _credit} | other_creditors],
         transactions
       ) do
    debt = Money.neg(neg_debt)
    new_transaction = %{from: debtor, to: creditor, amount: debt}

    make_transactions(
      other_debtors,
      other_creditors,
      [new_transaction | transactions]
    )
  end

  defp add_transaction_from_cmp(
         :gt,
         [{debtor, neg_debt} | other_debtors],
         [{creditor, credit} | other_creditors],
         transactions
       ) do
    debt = Money.neg(neg_debt)
    new_transaction = %{from: debtor, to: creditor, amount: debt}

    make_transactions(
      other_debtors,
      [{creditor, Money.subtract(credit, debt)} | other_creditors],
      [new_transaction | transactions]
    )
  end

  defp add_transaction_from_cmp(
         :lt,
         [{debtor, neg_debt} | other_debtors],
         [{creditor, credit} | other_creditors],
         transactions
       ) do
    new_transaction = %{from: debtor, to: creditor, amount: credit}

    make_transactions(
      [{debtor, Money.add(neg_debt, credit)} | other_debtors],
      other_creditors,
      [new_transaction | transactions]
    )
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
