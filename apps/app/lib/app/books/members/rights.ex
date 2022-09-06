defmodule App.Books.Members.Rights do
  @moduledoc """
  Rights are the ability to do one or more actions in a book.

  Member are associated a role in a book. The role is represented by
  the module `App.Books.Members.Role`. It defines their capacity to do
  or not to do actions inside the book. These capacities are represented
  by rights.

  ## Exhaustive list of rights

  - delete_book: Allow to delete a book
  - handle_money_transfers: Allow to create, update, and delete money transfers
  - invite_new_member: Allow to invite a new member in the book
  - update_book: Allow to modify the book (e.g. name)

  """

  alias App.Books.Members.Role
  alias App.Books.Members.BookMember

  @type t ::
          :delete_book
          | :handle_money_transfers
          | :invite_new_member
          | :update_book

  @creator_rights [:delete_book, :handle_money_transfers, :invite_new_member, :update_book]
  @spec creator_rights() :: [t()]
  def creator_rights, do: @creator_rights

  @member_rights [:handle_money_transfers]
  @spec member_rights() :: [t()]
  def member_rights, do: @member_rights

  @doc """
  Checks if a book member can delete the book.
  """
  @spec member_can_delete_book?(BookMember.t()) :: boolean()
  def member_can_delete_book?(member) do
    member_has_right?(member, :delete_book)
  end

  defp member_has_right?(member, right) do
    Role.has_right?(member.role, right)
  end
end
