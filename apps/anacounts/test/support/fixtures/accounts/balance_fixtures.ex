defmodule Anacounts.Accounts.BalanceFixtures do
  @moduledoc """
  Fixtures for the `Accounts.Balance` context
  """

  def valid_transfer_params_means_code, do: :divide_equally
  def valid_transfer_params_params, do: %{}

  def valid_transfer_params(attrs \\ %{}) do
    Enum.into(attrs, %{
      means_code: valid_transfer_params_means_code(),
      params: valid_transfer_params_params()
    })
  end
end
