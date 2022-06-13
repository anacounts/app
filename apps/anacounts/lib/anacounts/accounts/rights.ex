defmodule Anacounts.Accounts.Rights do
  @moduledoc """
  The ability to do some action on a book.
  Users have a role in their book with an associated role. This role
  defines their capacity to do or not to do some actions on the book.
  These capacities are represented by rights.
  """

  alias Anacounts.Accounts

  @type t :: atom()

  @all [:delete_book]
  def all, do: @all

  @spec member_has_right?(Accounts.BookMember.t(), t()) :: boolean()
  def member_has_right?(member, right) do
    Accounts.Role.has_right?(member.role, right)
  end
end
