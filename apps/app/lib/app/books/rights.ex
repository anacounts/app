defmodule App.Books.Rights do
  @moduledoc """
  Rights are the ability to do one or more actions in a book.

  Member are associated a role in a book. The role is represented by
  the module `App.Books.Role`. It defines their capacity to do
  or not to do actions inside the book. These capacities are represented
  by rights.

  ## Exhaustive list of rights

  - delete_book: Allow to delete a book
  - edit_book: Allow to modify the book (e.g. name)
  - handle_money_transfers: Allow to create, update, and delete money transfers
  - invite_new_member: Allow to invite a new member in the book

  """

  alias App.Books.Role

  @type t ::
          :delete_book
          | :edit_book
          | :handle_money_transfers
          | :invite_new_member

  @all_rights [
    :delete_book,
    :edit_book,
    :handle_money_transfers,
    :invite_new_member
  ]

  @creator_rights @all_rights
  @spec creator_rights() :: [t()]
  def creator_rights, do: @creator_rights

  @member_rights [:handle_money_transfers]
  @spec member_rights() :: [t()]
  def member_rights, do: @member_rights

  @viewer_rights []
  @spec viewer_rights() :: [t()]
  def viewer_rights, do: @viewer_rights

  for right <- @all_rights do
    @doc """
    Check if a member can do the action `#{right}`.

    ## Examples

        iex> can_member_#{right}?(%BookMember{role: :creator})
        true

        iex> can_member_#{right}?(%BookMember{role: :viewer})
        false

    """
    # Credo: creating an atom from a string here is safe, as they are only created
    # at compile-time, from a list of known atoms.
    # credo:disable-for-next-line Credo.Check.Warning.UnsafeToAtom
    def unquote(:"can_member_#{right}?")(member) do
      Role.has_right?(member.role, unquote(right))
    end
  end
end
