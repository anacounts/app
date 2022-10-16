defmodule App.BalanceFixtures do
  @moduledoc """
  Fixtures for the `App.Balance` context
  """

  alias App.Balance

  def valid_balance_transfer_means_code, do: :divide_equally
  def valid_balance_transfer_params, do: nil

  def valid_balance_transfer_params_attrs(attrs \\ %{}) do
    Enum.into(attrs, %{
      means_code: valid_balance_transfer_means_code(),
      params: valid_balance_transfer_params()
    })
  end

  def user_balance_config_fixture(user, attrs \\ %{}) do
    {:ok, user_config} =
      Balance.get_user_config_or_default(user)
      |> Balance.update_user_config(Map.new(attrs))

    user_config
  end

  def setup_user_balance_config_fixture(%{user: user} = context) do
    Map.put(context, :user_balance_config, user_balance_config_fixture(user))
  end
end
