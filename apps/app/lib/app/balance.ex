defmodule App.Balance do
  @moduledoc """
  Context to compute book members' balance and the transactions to adjust it.
  """

  alias App.Repo

  alias App.Books.BookMember
  alias App.Transfers

  @type error_reasons :: [String.t()]

  @doc """
  Compute the `:balance` field of book members.

  ## Examples

      iex> fill_members_balance([%BookMember{balance: nil}])
      [%BookMember{balance: Decimal.new(0)}]

  """
  def fill_members_balance(members) do
    transfers =
      members
      |> Transfers.list_transfers_of_members()
      |> preload_peers(members)
      |> compute_total_peer_weight()

    members
    |> reset_members_balance()
    |> adjust_balance_from_transfers(transfers)
    |> round_members_balance()
  end

  # Preload peers of transfers and fill their `:member` field.
  # The member of the peer can be used to create more precise
  # errors if the computation of the balance is not possible.
  defp preload_peers(transfers, members) when is_list(transfers) do
    members_by_id = Map.new(members, &{&1.id, &1})

    transfers
    |> Repo.preload(:peers)
    |> Enum.map(&fill_peers_members(&1, members_by_id))
  end

  defp fill_peers_members(transfer, members_by_id) do
    Map.update!(transfer, :peers, fn peers ->
      Enum.map(peers, fn peer ->
        member = Map.fetch!(members_by_id, peer.member_id)
        %{peer | member: member}
      end)
    end)
  end

  defp compute_total_peer_weight(transfers) when is_list(transfers) do
    transfers
    |> Enum.group_by(& &1.balance_params.means_code)
    |> Enum.flat_map(&compute_peers_total_weight/1)
    |> Enum.map(fn
      {:ok, transfer} ->
        total_peer_weight =
          Enum.reduce(transfer.peers, Decimal.new(0), &Decimal.add(&2, &1.total_weight))

        {:ok, %{transfer | total_peer_weight: total_peer_weight}}

      {:error, _reason, _transfer} = error ->
        error
    end)
  end

  defp compute_peers_total_weight({:divide_equally, transfers}) do
    Enum.map(transfers, fn transfer ->
      {:ok, %{transfer | peers: peers_with_total_weight(transfer.peers, & &1.weight)}}
    end)
  end

  defp compute_peers_total_weight({:weight_by_income, transfers}) do
    # Peers are already preloaded, but we need their balance config
    transfers = Repo.preload(transfers, peers: [:balance_config])

    Enum.map(transfers, fn transfer ->
      all_annual_incomes_set? =
        Enum.all?(transfer.peers, fn peer ->
          peer.balance_config != nil and peer.balance_config.annual_income != nil
        end)

      if all_annual_incomes_set? do
        peers =
          peers_with_total_weight(
            transfer.peers,
            &Decimal.mult(&1.weight, &1.balance_config.annual_income)
          )

        {:ok, %{transfer | peers: peers}}
      else
        {:error, "some members did not set their annual income", transfer}
      end
    end)
  end

  defp peers_with_total_weight(peers, weight_fun) do
    Enum.map(peers, &%{&1 | total_weight: weight_fun.(&1)})
  end

  defp reset_members_balance(members) do
    Enum.map(members, fn member -> %{member | balance: Money.new!(:EUR, 0)} end)
  end

  defp adjust_balance_from_transfers(members, []), do: members

  defp adjust_balance_from_transfers(members, [{:ok, transfer} | other_transfers]) do
    members
    |> adjust_balance_from_peers(transfer, transfer.peers)
    |> adjust_balance_from_transfers(other_transfers)
  end

  defp adjust_balance_from_transfers(members, [{:error, reason, transfer} | other_transfers]) do
    members
    |> add_balance_error_on_members_in_transfer(reason, transfer)
    |> adjust_balance_from_transfers(other_transfers)
  end

  defp adjust_balance_from_peers(members, _transfer, []), do: members

  defp adjust_balance_from_peers(members, %{tenant_id: id} = transfer, [%{member_id: id} | peers]) do
    adjust_balance_from_peers(members, transfer, peers)
  end

  defp adjust_balance_from_peers(members, transfer, [peer | other_peers]) do
    relative_weight = Decimal.div(peer.total_weight, transfer.total_peer_weight)
    transfer_amount = Transfers.amount(transfer)
    adjustment_amount = Money.mult!(transfer_amount, relative_weight)

    member_id = peer.member_id
    tenant_id = transfer.tenant_id

    members
    |> Enum.map(fn
      # If a member's balance has already been corrupted, it cannot be computed correctly
      %{balance: {:error, _}} = member ->
        member

      %{id: ^member_id} = member ->
        %{member | balance: Money.sub!(member.balance, adjustment_amount)}

      %{id: ^tenant_id} = member ->
        %{member | balance: Money.add!(member.balance, adjustment_amount)}

      member ->
        member
    end)
    |> adjust_balance_from_peers(transfer, other_peers)
  end

  defp add_balance_error_on_members_in_transfer(members, reason, transfer) do
    Enum.map(members, fn member ->
      transfer_members_ids = [transfer.tenant_id | Enum.map(transfer.peers, & &1.member_id)]

      if member.id in transfer_members_ids,
        do: add_balance_error(member, reason),
        else: member
    end)
  end

  # add a reason to the balance error list, or initialize the list
  defp add_balance_error(member, reason) do
    reasons =
      case member.balance do
        {:error, reasons} -> [reason | reasons]
        _ -> [reason]
      end

    %{member | balance: {:error, reasons}}
  end

  defp round_members_balance(members) do
    Enum.map(members, fn member ->
      if has_balance_error?(member),
        do: member,
        else: %{member | balance: Money.round(member.balance)}
    end)
  end

  @doc """
  Checks if the computed balance of the member has an error.
  """
  @spec has_balance_error?(BookMember.t()) :: boolean()
  def has_balance_error?(member) do
    match?({:error, _reasons}, member.balance)
  end

  @spec member_balance_error_reasons(BookMember.t()) :: error_reasons() | nil
  defp member_balance_error_reasons(member) do
    case member.balance do
      {:error, reasons} -> reasons
      _ -> nil
    end
  end

  @doc """
  Checks if the computed balance of members does not have errors and is zero.
  """
  @spec unbalanced?([BookMember.t()]) :: boolean()
  def unbalanced?(members) do
    Enum.any?(members, fn member ->
      has_balance_error?(member) or not Money.zero?(member.balance)
    end)
  end

  @typedoc """
  A type representing a transaction between two members.
  This is used to display required operations to balance money between members.
  """
  @type transaction :: %{
          id: String.t(),
          from: BookMember.t(),
          to: BookMember.t(),
          amount: Money.t()
        }

  @doc """
  Compute the transactions to balance the book members. The result is computed based on
  the `:balance` field of book members. Make it is filled by `fill_members_balance/1`
  before.

  Returns `:error` if any balance is set to an error state.

  The total sum of balanced money must be equal to 0, otherwise the function will crash.

  ## Examples

      iex> transactions([member1])
      {:ok, []}

      iex> transactions([member1, member2])
      {:ok, [%{amount: Money.new!(:EUR, 10), from: member1, to: member2}]}

      iex> transactions([member_with_error_in_balance, member2])
      {:error, ["reason1", "reason2"]}

  """
  @spec transactions([BookMember.t()]) :: {:ok, [transaction()]} | {:error, error_reasons()}
  def transactions(members) do
    error_reasons = Enum.find_value(members, &member_balance_error_reasons/1)

    if error_reasons do
      {:error, error_reasons}
    else
      {debtors, creditors} =
        members
        |> Enum.reject(&Money.zero?(&1.balance))
        |> Enum.split_with(&Money.negative?(&1.balance))

      {:ok, make_transactions(debtors, creditors, [])}
    end
  end

  # Creates necessary transactions between creditors and debtors
  # to balance things. The total sum of creditors and debtors should be
  # equal to 0, or the function will crash.
  defp make_transactions([], [], transactions), do: transactions

  defp make_transactions(
         [debtor | _other_debtors] = all_debtors,
         [creditor | _other_creditors] = all_creditors,
         transactions
       ) do
    debt = Money.mult!(debtor.balance, -1)

    Money.compare!(creditor.balance, debt)
    |> add_transaction_from_cmp(all_debtors, all_creditors, transactions)
  end

  defp add_transaction_from_cmp(
         :eq,
         [debtor | other_debtors],
         [creditor | other_creditors],
         transactions
       ) do
    debt = Money.mult!(debtor.balance, -1)
    new_transaction = transaction_for(debtor, creditor, debt)

    make_transactions(
      other_debtors,
      other_creditors,
      [new_transaction | transactions]
    )
  end

  defp add_transaction_from_cmp(
         :gt,
         [debtor | other_debtors],
         [creditor | other_creditors],
         transactions
       ) do
    debt = Money.mult!(debtor.balance, -1)
    new_transaction = transaction_for(debtor, creditor, debt)

    make_transactions(
      other_debtors,
      [%{creditor | balance: Money.sub!(creditor.balance, debt)} | other_creditors],
      [new_transaction | transactions]
    )
  end

  defp add_transaction_from_cmp(
         :lt,
         [debtor | other_debtors],
         [creditor | other_creditors],
         transactions
       ) do
    new_transaction = transaction_for(debtor, creditor, creditor.balance)

    make_transactions(
      [%{debtor | balance: Money.add!(debtor.balance, creditor.balance)} | other_debtors],
      other_creditors,
      [new_transaction | transactions]
    )
  end

  defp transaction_for(debtor, creditor, amount) do
    %{
      id: transaction_id(debtor, creditor),
      from: debtor,
      to: creditor,
      amount: amount
    }
  end

  defp transaction_id(debtor, creditor), do: "#{debtor.id}-#{creditor.id}"
end
