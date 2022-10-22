defmodule App.Balance.Means.WeightByIncome do
  @moduledoc """
  Implements `App.Balance.Means` behaviour.

  Divides money transfer among peers according their income.
  """

  @behaviour App.Balance.Means

  import Ecto.Query
  alias App.Repo

  alias App.Balance.Config.UserConfig
  alias App.Books.Members
  alias App.Transfers.MoneyTransfer
  alias App.Transfers.Peer

  @impl App.Balance.Means
  def balance_transfer_by_peer(money_transfer) do
    case peers_income(money_transfer) do
      {:ok, peers_income} ->
        transfer_amount = MoneyTransfer.amount(money_transfer)
        total_weight = total_weight(peers_income)

        peers_balance =
          Enum.map(peers_income, fn %{peer: peer, income: income} ->
            relative_weight =
              Decimal.mult(peer.weight, income)
              |> Decimal.div(total_weight)

            peer_amount = Money.multiply(transfer_amount, relative_weight)

            %{
              from: peer.member_id,
              to: money_transfer.tenant_id,
              amount: peer_amount,
              transfer_id: money_transfer.id
            }
          end)

        {:ok, peers_balance}

      {:error, _} = error ->
        error
    end
  end

  defp peers_income(money_transfer) do
    # TODO There should be no querying nor data fetching here

    incomes =
      peers_and_incomes_query(money_transfer)
      |> Repo.all()

    if errors = incomes_errors(incomes) do
      {:error, errors}
    else
      {:ok, incomes}
    end
  end

  defp peers_and_incomes_query(money_transfer) do
    base_query =
      Peer.base_query()
      |> Peer.where_transfer_id(money_transfer.id)
      |> Peer.join_member()
      |> Members.join_user()

    from [peer: peer, user: user] in base_query,
      left_join: user_config in UserConfig,
      on: user_config.user_id == user.id,
      select: %{
        peer: peer,
        income: user_config.annual_income,
        display_name: user.display_name
      }
  end

  defp incomes_errors(incomes) do
    errors_rows =
      incomes
      |> Enum.filter(&is_nil(&1.income))
      |> Enum.map(&"#{&1.display_name} did not parameter their income for \"Weight By Income\"")

    unless Enum.empty?(errors_rows), do: errors_rows
  end

  defp total_weight(peers_income)
  defp total_weight([]), do: Decimal.new(0)

  defp total_weight([peer_income | rest]) do
    Decimal.mult(peer_income.peer.weight, peer_income.income)
    |> Decimal.add(total_weight(rest))
  end
end
