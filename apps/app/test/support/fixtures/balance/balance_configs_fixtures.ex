defmodule App.Balance.BalanceConfigsFixtures do
  @moduledoc """
  Fixtures for the `App.Balance.BalanceConfigs` context
  """

  alias App.Repo

  alias App.Accounts.User
  alias App.Balance.BalanceConfig

  def balance_config_attributes(owner, attrs \\ %{}) do
    Enum.into(attrs, %{
      owner_id: owner.id,
      created_for: :user,
      start_date_of_validity: DateTime.utc_now(),
      annual_income: 1234
    })
  end

  def user_balance_config_fixture(user, attrs \\ %{}) do
    {:ok, %{balance_config: balance_config}} =
      Ecto.Multi.new()
      |> Ecto.Multi.insert(
        :balance_config,
        BalanceConfig.changeset(%BalanceConfig{}, balance_config_attributes(user, attrs))
      )
      |> Ecto.Multi.update(
        :user,
        &User.balance_config_changeset(user, %{balance_config_id: &1.balance_config.id})
      )
      |> Repo.transaction()

    balance_config
  end
end
