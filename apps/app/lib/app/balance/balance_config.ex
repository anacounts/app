defmodule App.Balance.BalanceConfig do
  @moduledoc """
  A configuration containing data for balancing the money transfers. This therefore
  includes private data, which is encrypted in the database.

  # XXX This is a work in progress. The following is a draft of the documentation.

  Balance configurations are referenced by users, user's history, book members,
  members's history and peers. Each one of them can be references by multiple entities
  at the same time.

  ## History

  Balance configurations are immutable. When updating a balance configuration, a new one
  is created and linked to the entity. For users and book members, the old configuration
  is kept in their `:balance_config_history` field, except if is not referenced by any
  entity, in which case it is deleted.

  ## Confidential information

  Due to the nature of the data, most of balance configurations' fields are encrypted in
  the database using Cloak and Cloak.Ecto.

  This information should never be displayed to anyone but their owner. The owner is a
  user referenced by the `:owner` association.

  As an extra security measure, balance configurations have a `:created_for` field
  indicating whether they were created for a user or a book member. This enables to do
  extra checks when linking a balance configuration to a user or a book member.
  For example, a balance configuration created for a book member should not be linked to
  another book member.

  ## Lifecycle

  The lifecycle of a balance configuration depends on what entity they are referenced by.
  Note that they may be referenced by different entities, and that the entities
  referencing it may change during the lifetime of the configuration.

  The overall lifecycle of balance configurations was designed to answer two problems:
  - the balance configurations must have some kind of "history", so when a user changes
    their annual income, the old configuration is kept and still referenced by peers and
    members,
  - an independent book member must be able to have their own balance configuration.
    This allows both to have members without users in the first place, and users to
    leave book, leaving an independent book member thereafter.

  Note that the deletion of balance configs is handled in a different part of the
  documentation, being common to all entities.

  ### Users

  Users may create a new balance configuration at any time. When they do, the members
  that reference the old balance configuration are updated to reference the new one.

  New balances are created with a start date of validity that can only be past or
  present. Associated peers linked to a transfer which date is later than this date
  are updated to reference the new balance configuration.

  Old balance configurations are stored in the users `:balance_config_history` field.

  ### Book members

  When a book member is created with a user, it is linked to the balance configuration of
  the user. When created independantly, no configuration is created.

  A new configuration can be created for independent book members at any time, which
  start date of validity must also be past or present.

  When a user is invited, accepts the invitation, and is linked to a member, their
  balance configuration is linked to the member. Before that, the balance config of
  the book member should try to be deleted.

  At any point, if a configuration is linked to a member, the existing peers'
  configuration is updated if the transfer date is later than the start date of validity,
  or if they are not linked to a balance configuration.

  Old balance configurations are stored in the members `:balance_config_history` field.

  ### Peers

  When a peer is created through a money transfer, it is linked to the balance config of
  the linked member. The member may not have a balance config, in which case the peer
  will not be linked to a balance config either.

  ## Deletion

  A balance configuration can only be deleted if no entity references it. To make
  deletion the least painful possible, all entities referencing a balance config have
  their foreign key set to RESTRICT. This way, when trying to delete an entity, the app
  will also try to delete their balance config: if the balance config is referenced by
  another entity, the operation will fail, but the error can safely be ignored.

  """
  use Ecto.Schema
  import Ecto.Changeset

  alias App.Accounts.User
  alias App.Books.BookMember

  @type id :: integer()

  @type t :: %__MODULE__{
          id: id(),
          annual_income: non_neg_integer(),
          user: User.t() | nil,
          user_id: User.id() | nil,
          book_member: BookMember.t() | nil,
          book_member_id: BookMember.id() | nil
        }

  @derive {Inspect, only: [:id, :user, :user_id]}
  schema "balance_configs" do
    field :annual_income, App.Encrypted.Integer

    # a balance config is associated to either a user or a book member, but not both
    # see @moduledoc for more details
    belongs_to :user, User
    belongs_to :book_member, BookMember

    timestamps()
  end

  def changeset(struct, attrs) do
    struct
    |> cast(attrs, [:annual_income])
    |> validate_annual_income()
    |> validate_user_id()
    |> validate_book_member_id()
  end

  defp validate_annual_income(changeset) do
    changeset
    |> validate_number(:annual_income, greater_than_or_equal_to: 0)
  end

  defp validate_user_id(changeset) do
    changeset
    |> foreign_key_constraint(:user_id)
  end

  defp validate_book_member_id(changeset) do
    changeset
    |> foreign_key_constraint(:book_member_id)
  end
end
