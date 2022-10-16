defmodule App.BalanceFixtures do
  @moduledoc """
  Fixtures for the `App.Balance` context
  """

  def valid_balance_transfer_means_code, do: :divide_equally
  def valid_balance_transfer_params, do: nil

  def valid_balance_transfer_params_attrs(attrs \\ %{}) do
    Enum.into(attrs, %{
      means_code: valid_balance_transfer_means_code(),
      params: valid_balance_transfer_params()
    })
  end
end
