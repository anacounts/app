defmodule App.Balance.BalanceConfigsFixtures do
  @moduledoc """
  Fixtures for the `App.Balance.BalanceConfigs` context
  """

  alias App.Balance.BalanceConfigs

  def user_balance_config_fixture(user, attrs \\ %{}) do
    clean_attrs = Enum.into(attrs, %{})

    {:ok, user_config} =
      user
      |> BalanceConfigs.get_user_config_or_default()
      |> BalanceConfigs.update_user_config(clean_attrs)

    user_config
  end
end
