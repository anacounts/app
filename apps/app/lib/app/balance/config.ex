defmodule App.Balance.Config do
  @moduledoc """
  The configuration related to balancing.

  This currently only includes configuration per user, but should evolve to
  include configuration per transfer, as the two are closely related.
  """
  alias App.Auth.User
  alias App.Balance.Config.UserConfig

  alias App.Repo

  @doc """
  Get the user's balance configuration. If the user does not have a configuration,
  returns the default configuration.

  ## Examples

      iex> get_user_config_or_default(user)
      %UserConfig{}

      iex> get_user_config_or_default(user_without_config)
      %UserConfig{}

  """
  @spec get_user_config_or_default(User.t()) :: UserConfig.t() | nil
  def get_user_config_or_default(%User{} = user) do
    user_config = user_config(user)

    user_config || %UserConfig{}
  end

  defp user_config(user) do
    Repo.get(UserConfig, user.balance_config_id)
  end

  @doc """
  Update the user's balance configuration. If the passed `user_config` was built and not
  loaded from the database, it will be inserted instead of updated.

  ## Examples

      iex> update_user_config(user_config, %{annual_income: 42})
      {:ok, %UserConfig{}}

      iex> update_user_config(%UserConfig{}, %{annual_income: 42})
      {:ok, %UserConfig{}}

      iex> update_user_config(user_config, %{annual_income: -1})
      {:error, %Ecto.Changeset{}}

  """
  @spec update_user_config(UserConfig.t(), map()) ::
          {:ok, UserConfig.t()} | {:error, Ecto.Changeset.t()}
  def update_user_config(user_config, attrs) do
    user_config
    |> UserConfig.changeset(attrs)
    |> Repo.insert_or_update()
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking user's balance configuration changes.

  ## Examples

      iex> change_user_config(user_config)
      %Ecto.Changeset{data: %UserConfig{}}

  """
  @spec change_user_config(UserConfig.t(), map()) :: Ecto.Changeset.t()
  def change_user_config(%UserConfig{} = user_config, params \\ %{}) do
    UserConfig.changeset(user_config, params)
  end
end
