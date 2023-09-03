defmodule App.Balance.BalanceConfigs do
  @moduledoc """
  The configuration related to balancing.

  To know more about the balance config lifecycle, see `App.Balance.BalanceConfig`.
  """
  import Ecto.Query

  alias App.Accounts.User
  alias App.Balance.BalanceConfig
  alias App.Books.BookMember

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
    user_balance_config(user) ||
      %BalanceConfig{
        owner: user,
        owner_id: user.id,
        created_for: :user,
        start_date_of_validity: DateTime.utc_now(:second)
      }
  end

  defp user_balance_config(%{balance_config_id: nil} = _user), do: nil

  defp user_balance_config(user) do
    Repo.get(BalanceConfig, user.balance_config_id)
  end

  @doc """
  Update the balance configuration of a user by creating a new one and linking the user
  to it.

  This also updates members linked to the user to use the new one.

  See `BalanceConfig` for more details.

  ## Examples

      iex> update_user_balance_config(user, balance_config, %{annual_income: 42})
      {:ok, %BalanceConfig{}}

      iex> update_user_balance_config(user, balance_config, %{annual_income: -1})
      {:error, %Ecto.Changeset{}}

  """
  @spec update_user_balance_config(User.t(), BalanceConfig.t(), map()) ::
          {:ok, BalanceConfig.t()} | {:error, Ecto.Changeset.t()}
  def update_user_balance_config(%User{} = user, %BalanceConfig{} = old_balance_config, attrs) do
    Ecto.Multi.new()
    |> Ecto.Multi.insert(:new_balance_config, fn _ ->
      BalanceConfig.copy_changeset(old_balance_config, attrs)
    end)
    |> Ecto.Multi.update(:user, fn %{new_balance_config: new_balance_config} ->
      User.balance_config_changeset(user, %{balance_config_id: new_balance_config.id})
    end)
    |> update_members_multi()
    |> Repo.transaction()
    |> case do
      {:ok, %{new_balance_config: new_balance_config}} ->
        {:ok, new_balance_config}

      {:error, :new_balance_config, changeset, _changes} ->
        {:error, changeset}
    end
  end

  # update members that are linked to the user
  defp update_members_multi(multi) do
    Ecto.Multi.update_all(
      multi,
      :members,
      fn %{new_balance_config: new_balance_config, user: user} ->
        from m in BookMember,
          where: m.user_id == ^user.id,
          update: [set: [balance_config_id: ^new_balance_config.id]]
      end,
      []
    )
  end

  @doc """
  Link a member to the user's balance configuration.
  """
  @spec link_user_balance_configs_to_member!(User.t(), BookMember.t()) :: :ok
  def link_user_balance_configs_to_member!(user, member) do
    {1, nil} =
      from(BookMember, where: [id: ^member.id])
      |> Repo.update_all(set: [balance_config_id: user.balance_config_id])

    :ok
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

  @doc """
  Try to delete a balance configuration. If the balance configuration is linked to
  an entity, this will fail silently.

  ## Examples

      iex> try_to_delete_balance_config(balance_config_with_no_links)
      :ok

      iex> try_to_delete_balance_config(balance_config_that_will_not_be_deleted)
      :ok

  """
  @spec try_to_delete_balance_config(BalanceConfig.t()) :: :ok
  def try_to_delete_balance_config(%BalanceConfig{} = balance_config) do
    Repo.savepoint(fn ->
      from(BalanceConfig, where: [id: ^balance_config.id])
      |> Repo.delete_all()
    end)

    :ok
  end
end
