defmodule App.Balance.BalanceConfig do
  @moduledoc """
  A configuration containing data for balancing the money transfers. This therefore
  includes private data, which is encrypted in the database.

  **Warning: The following documentation is a draft of the final desired state.**
  This in not implemented yet, nor does it pretend being the final state of the context
  documentation.

  To ease the process, simplfications have been done and are used before enhancement of
  the application. A "State of the art" section can be found at the end of this
  documentation.

  _End of the warning. Enjoy the doc !_

  Balance configurations are referenced by users, book members, and peers. They can be
  referenced by multiple entities at the same time.

  ## History

  Balance configurations are immutable. When updating a balance configuration, a new one
  is created and linked to the entity.
  Users and members reference their balance configurations through a join table, allowing
  to have a history of the configuration, along with a period of validity of each entry.
  Peers on the other side have a simple foreign key to the balance configuration, since
  they are fixed in time.

  ## Confidential information

  Due to the nature of the data, the balance configurations' fields filled by the user
  are encrypted in the database using Cloak and Cloak.Ecto.

  This information should never be displayed to anyone but their owner. The owner is a
  user referenced by the `:owner` association. A balance configuration may not have a
  owner - e.g. if the user deleted their account.

  As an extra security measure, balance configurations have a `:created_for` field
  indicating whether they were created for a user or a book member. This enables to do
  extra checks when linking a balance configuration to a user or a book member.
  For example, a balance configuration created for a user should not be linked to another
  user.

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
  XXX What to do if the period of validity of the new config overlaps with other configs ?

  Balance configuration are stored in a join entity `UserBalanceConfig`, which contains
  the period of validity of the configuration.

  ### Book members

  When a book member is created, no configuration is created.

  A new configuration can be created for independent book members at any time, which
  start date of validity must also be past or present.

  When a user is invited, accepts the invitation, and is linked to a member, a link
  between the member and their balance configuration is created, starting at the time
  the invitation is accepted. The old balance config of the book member is then attempted
  to be deleted. Finally, if peers associated with the members do not have a
  balance config, they are updated to reference the new balance config.

  XXX What to do if the period of validity of the new config overlaps with other configs ?

  Balance configuration are stored in a join entity `MemberBalanceConfig`, which contains
  the period of validity of the configuration.

  ### Peers

  When a peer is created through a money transfer, it is linked to the balance config of
  the linked member. If the transfer's date is modified, the peer is updated to reference
  the balance config of the member at the time of the transfer, or the first one.

  ## Deletion

  A balance configuration can only be deleted if no entity references it. To make
  deletion the least painful possible, all entities referencing a balance config have
  their foreign key set to RESTRICT.

  XXX Should we really try to delete the balance config when deleting an entity ?
      This way, when trying to delete an entity, the app will also try to delete their balance config:
      if the balance config is referenced by another entity, the operation will fail, but the error can safely be ignored.

  ## FIXME

  - `balance_configs.owner_id` references `users` with a `ON DELETE CASCADE` foreign key.
    Hence, when a user is deleted, we will try to delete the balance config they own, which most likely
    isn't possible because they will be referenced elsewhere.
    To fix: owner_id nullable

  ## State of the art

  To simplify implementation, there is no history for now. All entities simply reference
  the latest balance configuration through a `balance_config` association.

  When a user creates a new balance config, the members associated to the user are updated
  to use the new balance config.

  When a member is linked to a user, the member's balance config is updated to the user's.
  The old balance config of the member is then attempted to be deleted.

  When a peer is created, it is linked to the balance config of the member.

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
