defmodule App.Balance.BalanceConfigsFixtures do
  @moduledoc """
  Fixtures for the `App.Balance.BalanceConfigs` context
  """

  alias App.Repo

  alias App.Accounts.User
  alias App.Balance.BalanceConfig
  alias App.Books.BookMember
  alias App.Transfers.Peer

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

  def member_balance_config_link_fixture(member, balance_config) do
    {:ok, balance_config} =
      member
      |> BookMember.balance_config_changeset(%{balance_config_id: balance_config.id})
      |> Repo.update()

    balance_config
  end

  def peer_balance_config_link_fixture(peer, balance_config) do
    {:ok, balance_config} =
      peer
      |> Peer.balance_config_changeset(%{balance_config_id: balance_config.id})
      |> Repo.update()

    balance_config
  end
end
