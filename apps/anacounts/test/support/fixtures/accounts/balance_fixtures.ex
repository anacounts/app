defmodule Anacounts.Accounts.BalanceFixtures do
  @moduledoc """
  Fixtures for the `Accounts.Balance` context
  """

  def valid_balance_means_code, do: :divide_equally
  def valid_balance_params, do: %{}

  def valid_balance_transfer_params_attrs(attrs \\ %{}) do
    Enum.into(attrs, %{
      means_code: valid_balance_means_code(),
      params: valid_balance_params()
    })
  end
end
