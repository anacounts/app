defmodule App.Balance.BalanceConfigs do
  @moduledoc """
  The configuration related to balancing.

  To know more about the balance config lifecycle, see `App.Balance.BalanceConfig`.
  """
  import Ecto.Query

  alias App.Balance.BalanceConfig
  alias App.Books.BookMember
  alias App.Repo

  @doc """
  Check if a member has revenues set in their balance configuration.

  Returns `false` both if the member has no balance configuration or if the balance
  configuration has no annual income set.
  """
  @spec member_has_revenues?(BookMember.t()) :: boolean()
  def member_has_revenues?(%BookMember{balance_config_id: nil} = _member), do: false

  def member_has_revenues?(%BookMember{} = member) do
    from(balance_config in BalanceConfig,
      where: balance_config.id == ^member.balance_config_id,
      select: not is_nil(balance_config.annual_income)
    )
    |> Repo.one!()
  end

  @doc """
  Try to delete a balance configuration. If the balance configuration is linked to
  an entity, this will fail silently.
  """
  @spec try_to_delete_balance_config(BalanceConfig.t()) :: :ok
  def try_to_delete_balance_config(%BalanceConfig{} = balance_config) do
    balance_config
    |> Ecto.Changeset.cast(%{}, [])
    |> Ecto.Changeset.foreign_key_constraint(:book_members,
      name: "book_members_balance_config_id_fkey"
    )
    |> Ecto.Changeset.foreign_key_constraint(:peers,
      name: "transfers_peers_balance_config_id_fkey"
    )
    |> Repo.delete(mode: :savepoint)

    :ok
  end
end
