defmodule App.Balance.BalanceConfigs do
  @moduledoc """
  The configuration related to balancing.
  """
  import Ecto.Query

  alias App.Auth.User
  alias App.Balance.BalanceConfig

  alias App.Repo

  @doc """
  Get the balance configuration of a user.

  ## Examples

      iex> get_user_balance_config!(user)
      %BalanceConfig{}

      iex> get_user_balance_config!(user_without_config)
      %BalanceConfig{}

  """
  @spec get_user_balance_config!(User.t()) :: BalanceConfig.t() | nil
  def get_user_balance_config!(%User{} = user) do
    user_balance_config_query(user)
    |> Repo.one!()
  end

  defp user_balance_config_query(user) do
    from BalanceConfig,
      where: [user_id: ^user.id]
  end

  @doc """
  Update the balance configuration.

  ## Examples

      iex> update_balance_config(balance_config, %{annual_income: 42})
      {:ok, %BalanceConfig{}}

      iex> update_balance_config(balance_config, %{annual_income: -1})
      {:error, %Ecto.Changeset{}}

  """
  @spec update_balance_config(BalanceConfig.t(), map()) ::
          {:ok, BalanceConfig.t()} | {:error, Ecto.Changeset.t()}
  def update_balance_config(balance_config, attrs) do
    balance_config
    |> BalanceConfig.changeset(attrs)
    |> Repo.update()
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
