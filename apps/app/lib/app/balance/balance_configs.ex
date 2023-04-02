defmodule App.Balance.BalanceConfigs do
  @moduledoc """
  The configuration related to balancing.

  To know more about the balance config lifecycle, see `App.Balance.BalanceConfig`.
  """
  alias App.Accounts.User
  alias App.Balance.BalanceConfig

  alias App.Repo

  @doc """
  Get the user's balance configuration. If the user does not have a configuration,
  returns the default configuration.

  ## Examples

      iex> get_user_balance_config_or_default(user)
      %BalanceConfig{}

      iex> get_user_balance_config_or_default(user_without_config)
      %BalanceConfig{}

  """
  @spec get_user_balance_config_or_default(User.t()) :: BalanceConfig.t() | nil
  def get_user_balance_config_or_default(%User{} = user) do
    user_balance_config(user) || %BalanceConfig{owner: user, owner_id: user.id}
  end

  defp user_balance_config(%{balance_config_id: nil} = _user), do: nil

  defp user_balance_config(user) do
    Repo.get(BalanceConfig, user.balance_config_id)
  end

  @doc """
  Update the user's balance configuration. If the passed `balance_config` was built and not
  loaded from the database, it will be inserted instead of updated.

  ## Examples

      iex> update_balance_config(balance_config, %{annual_income: 42})
      {:ok, %BalanceConfig{}}

      iex> update_balance_config(%BalanceConfig{user_id: 11}, %{annual_income: 42})
      {:ok, %BalanceConfig{}}

      iex> update_balance_config(balance_config, %{annual_income: -1})
      {:error, %Ecto.Changeset{}}

  """
  @spec update_balance_config(BalanceConfig.t(), map()) ::
          {:ok, BalanceConfig.t()} | {:error, Ecto.Changeset.t()}
  def update_balance_config(balance_config, attrs) do
    balance_config
    |> BalanceConfig.changeset(attrs)
    |> Repo.insert_or_update()
  end

  @doc """
  Link a balance configuration to a user.

  XXX This function temporary. It is used during the reword of balance configs
  """
  @spec link_balance_config_to_user!(BalanceConfig.t(), User.t()) :: User.t()
  def link_balance_config_to_user!(%BalanceConfig{} = balance_config, %User{} = user) do
    {:ok, %{user: user}} =
      Ecto.Multi.new()
      |> Ecto.Multi.update(
        :user,
        User.balance_config_changeset(user, %{balance_config_id: balance_config.id})
      )
      |> Ecto.Multi.update(
        :balance_config,
        BalanceConfig.changeset(balance_config, %{owner_id: user.id})
      )
      |> Repo.transaction()

    user
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking balance configuration changes.

  ## Examples

      iex> change_balance_config(balance_config)
      %Ecto.Changeset{data: %BalanceConfig{}}

  """
  @spec change_balance_config(BalanceConfig.t(), map()) :: Ecto.Changeset.t()
  def change_balance_config(%BalanceConfig{} = balance_config, params \\ %{}) do
    BalanceConfig.changeset(balance_config, params)
  end
end
