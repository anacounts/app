defmodule App.Balance.BalanceConfigsFixtures do
  @moduledoc """
  Fixtures for the `App.Balance.BalanceConfigs` context
  """

  alias App.Repo

  alias App.Accounts.User
  alias App.Balance.BalanceConfig

  def user_balance_config_fixture(user, attrs \\ %{}) do
    clean_attrs = Enum.into(attrs, %{})

    {:ok, %{balance_config: balance_config}} =
      Ecto.Multi.new()
      |> Ecto.Multi.insert(
        :balance_config,
        BalanceConfig.changeset(%BalanceConfig{owner_id: user.id}, clean_attrs)
      )
      |> Ecto.Multi.update(
        :user,
        &User.balance_config_changeset(user, %{balance_config_id: &1.balance_config.id})
      )
      |> Repo.transaction()

    balance_config
  end
end
