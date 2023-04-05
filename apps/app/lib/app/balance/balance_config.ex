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

  @type id :: integer()

  @type t :: %__MODULE__{
          id: id(),
          annual_income: non_neg_integer() | nil,
          owner: User.t(),
          owner_id: User.id(),
          created_for: :user | :book_member,
          start_date_of_validity: DateTime.t(),
          inserted_at: NaiveDateTime.t(),
          updated_at: NaiveDateTime.t()
        }

  @derive {Inspect, only: [:id, :owner, :owner_id]}
  schema "balance_configs" do
    belongs_to :owner, User
    field :created_for, Ecto.Enum, values: [:user, :book_member]

    field :start_date_of_validity, :utc_datetime

    # Confidential information
    field :annual_income, App.Encrypted.Integer

    timestamps()
  end

  def changeset(struct, attrs) do
    struct
    |> cast(attrs, [:owner_id, :created_for, :start_date_of_validity, :annual_income])
    |> validate_owner_id()
    |> validate_created_for()
    |> validate_start_date_of_validity()
    |> validate_annual_income()
  end

  defp validate_owner_id(changeset) do
    changeset
    |> validate_required(:owner_id)
    |> foreign_key_constraint(:owner_id)
  end

  defp validate_created_for(changeset) do
    changeset
    |> validate_required(:created_for)
  end

  defp validate_start_date_of_validity(changeset) do
    changeset
    |> validate_required(:start_date_of_validity)
    |> validate_change(:start_date_of_validity, fn _, value ->
      if value < DateTime.utc_now() do
        []
      else
        [start_date_of_validity: "must be now or a past date"]
      end
    end)
  end

  defp validate_annual_income(changeset) do
    changeset
    |> validate_number(:annual_income, greater_than_or_equal_to: 0)
  end

  @doc """
  Create a change that copies the attributes of the given struct, except for the
  `:id`, `:inserted_at` and `:updated_at` fields, which are set to `nil`.

  Note that the `:start_date_of_validity` is set to the current time as a hack
  to prevent the user from setting a different date. This is temporary until
  we implement the logic to create new balance configs with a past start date.

  ## Examples

      iex> BalanceConfig.copy_changeset(%BalanceConfig{}, %{field: value})
      #Ecto.Changeset<...>

  """
  @spec copy_changeset(t(), map()) :: Ecto.Changeset.t()
  def copy_changeset(struct, attrs) do
    %{
      struct
      | id: nil,
        start_date_of_validity: DateTime.utc_now() |> DateTime.truncate(:second),
        inserted_at: nil,
        updated_at: nil
    }
    |> changeset(attrs)
  end
end
