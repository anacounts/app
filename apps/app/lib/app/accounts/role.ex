defmodule App.Accounts.Role do
  @moduledoc """
  Position a user has in a book. A user may have different roles in
  different books, but can only have one role in a particular book.
  The role of a user in a book defines its ability to do or not to do
  different actions - renaming or deleteing it, adding members, etc.

  The creator of a book always has a "creator" role, which gives him
  all the rights there can be on the book they created.
  """
  alias App.Accounts.Rights

  @type t :: atom()

  @roles %{
    creator: Rights.creator_rights(),
    member: Rights.member_rights()
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
