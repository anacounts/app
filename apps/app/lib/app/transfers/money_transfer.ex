defmodule App.Transfers.MoneyTransfer do
  @moduledoc """
  Entity representing money transfers. This includes both payments,
  incomes and reimbursements.
  """

  use Ecto.Schema

  import Ecto.Changeset

  alias App.Balance.TransferParams
  alias App.Books.Book
  alias App.Books.BookMember
  alias App.Transfers.Peer

  # the types
  @transfer_types [:payment, :income, :reimbursement]

  @type id :: integer()
  @type t :: %__MODULE__{
          id: id(),
          label: String.t(),
          amount: Money.t(),
          type: :payment | :income | :reimbursement,
          date: Date.t(),
          book: Book.t(),
          tenant: BookMember.t(),
          balance_params: TransferParams.t(),
          peers: Peer.t(),
          total_peer_weight: Decimal.t(),
          inserted_at: DateTime.t(),
          updated_at: DateTime.t()
        }

  schema "money_transfers" do
    field :label, :string
    field :amount, Money.Ecto.Composite.Type
    field :type, Ecto.Enum, values: @transfer_types
    field :date, :date

    belongs_to :book, Book
    belongs_to :tenant, BookMember

    # balance
    field :balance_params, TransferParams

    has_many :peers, Peer,
      foreign_key: :transfer_id,
      on_replace: :delete_if_exists

    # Sum of all the peer `:total_weight`. Depends on the transfer balance means
    field :total_peer_weight, :decimal, virtual: true

    timestamps()
  end

  ## Changesets

  def changeset(struct, attrs) do
    struct
    |> cast(attrs, [:label, :amount, :type, :date, :tenant_id, :balance_params])
    |> validate_label()
    |> validate_amount()
    |> validate_type()
    |> validate_tenant_id()
    |> validate_book_id()
    |> validate_balance_params()
  end

  def with_peers(changeset, with_changeset) do
    changeset
    |> cast_assoc(:peers, with: with_changeset)
  end

  defp validate_label(changeset) do
    changeset
    |> validate_required(:label)
    |> validate_length(:label, min: 1, max: 255)
  end

  defp validate_amount(changeset) do
    changeset
    |> validate_required(:amount)
  end

  defp validate_type(changeset) do
    changeset
    |> validate_required(:type)
  end

  defp validate_tenant_id(changeset) do
    changeset
    |> validate_required(:tenant_id)
    |> foreign_key_constraint(:tenant_id)
  end

  defp validate_book_id(changeset) do
    changeset
    |> validate_required(:book_id)
    |> foreign_key_constraint(:book_id)
  end

  defp validate_balance_params(changeset) do
    changeset
    |> validate_required(:balance_params)
  end
end
