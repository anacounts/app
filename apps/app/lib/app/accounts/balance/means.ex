defmodule App.Accounts.Balance.Means do
  @moduledoc """
  A behavior to represents means to divide transfer amount between peers.
  """

  alias App.Accounts.Balance
  alias App.Accounts.Balance.Means
  alias App.Transfers.MoneyTransfer

  # When adding a new balance means
  # - add the code to type `code` and module attribute `@codes` below
  # - update `from_code/1` below
  # - add a value to the database enum (e.g. see migration App.Repo.Migrations.AddMeansWeightByIncome)
  # - update `cast/1` and `params_mismatch/2` in TransferParams
  # - update `params_mismatch/2` in UserParams
  # - add the value to the GraphQL "balance_means_code" enum in BalanceTypes

  @type code :: :divide_equally | :weight_by_income

  @codes [:divide_equally, :weight_by_income]
  def codes, do: @codes

  @codes_with_user_params @codes -- [:divide_equally]
  def codes_with_user_params, do: @codes_with_user_params

  @doc """
  Divide the given money transfer between its associated peers.
  """
  @callback balance_transfer_by_peer(MoneyTransfer.t()) ::
              {:ok, [Balance.peer_balance()]} | {:error, String.t()}

  def balance_transfer_by_peer(transfer) do
    balance_params = transfer_balance_params(transfer)

    means = from_code(balance_params.means_code)
    means.balance_transfer_by_peer(transfer)
  end

  defp transfer_balance_params(transfer) do
    if transfer.balance_params do
      transfer.balance_params
    else
      transfer = App.Repo.preload(transfer, :book)
      transfer.book.default_balance_params
    end
  end

  defp from_code(:divide_equally), do: Means.DivideEqually
  defp from_code(:weight_by_income), do: Means.WeightByIncome
end
