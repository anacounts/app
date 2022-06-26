defmodule Anacounts.Accounts.Rights do
  @moduledoc """
  Rights are the ability to do one or more actions in a book.

  Member are associated a role in a book. The role is represented by
  Anacounts.Accounts.Role. It defines their capacity to do or not to do
  some actions on the book. These capacities are represented by rights.

  ## List of rights

  - delete_book: Allow to delete a book
  - handle_money_transfers: Allow to create, update, and delete money transfers
  - invite_new_member: Allow to invite a new member in the book

  """

  alias Anacounts.Accounts

  @type t :: atom()

  @creator_rights [:delete_book, :handle_money_transfers, :invite_new_member]
  def creator_rights, do: @creator_rights

  @member_rights [:handle_money_transfers]
  def member_rights, do: @member_rights

  @spec member_has_right?(Accounts.BookMember.t(), t()) :: boolean()
  def member_has_right?(member, right) do
    Accounts.Role.has_right?(member.role, right)
  end
end
