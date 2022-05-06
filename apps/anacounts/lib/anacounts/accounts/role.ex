defmodule Anacounts.Accounts.Role do
  alias Anacounts.Accounts.Rights

  @type t :: atom()

  @roles %{
    creator: Rights.all(),
    administrator: [],
    member: []
  }

  @role_ids Map.keys(@roles)
  def all, do: @role_ids

  @doc """
  Checks whether a role has a particular right or not.
  If the right does not exist, returns `false`.
  """
  @spec has_right?(t(), Right.t()) :: boolean()
  def has_right?(role, right) do
    right in Map.fetch!(@roles, role)
  end
end
