defmodule App.Balance.BalanceConfigsFixtures do
  @moduledoc """
  Fixtures for the `App.Balance.BalanceConfigs` context
  """

  alias App.Balance.BalanceConfigs

  def user_balance_config_fixture(user, attrs \\ %{}) do
    clean_attrs = Enum.into(attrs, %{})

    {:ok, balance_config} =
      user
      |> BalanceConfigs.get_user_config_or_default()
      |> BalanceConfigs.update_balance_config(clean_attrs)

    balance_config
  end
end
