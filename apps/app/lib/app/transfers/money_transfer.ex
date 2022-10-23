defmodule App.Transfers.MoneyTransfer do
  @moduledoc """
  Entity representing money transfers. This includes both payments,
  incomes and reimbursements.
  """

  use Ecto.Schema

  import Ecto.Changeset
  import Ecto.Query

  alias App.Balance
  alias App.Books.Book
  alias App.Books.Members.BookMember
  alias App.Transfers

  # the types
  @transfer_types [:payment, :income, :reimbursement]

  @type id :: integer()
  @type t :: %__MODULE__{
          id: id(),
          amount: Money.t(),
          type: :payment | :income | :reimbursement,
          book: Book.t(),
          tenant: BookMember.t(),
          balance_params: Balance.TransferParams.t(),
          peers: Transfers.Peer.t()
        }

  schema "transfers_money_transfers" do
    field :label, :string
    field :amount, Money.Ecto.Composite.Type
    field :type, Ecto.Enum, values: @transfer_types
    field :date, :date

    belongs_to :book, Book
    belongs_to :tenant, BookMember

    # balance
    field :balance_params, Balance.TransferParams

    has_many :peers, Transfers.Peer,
      foreign_key: :transfer_id,
      on_replace: :delete_if_exists

    timestamps()
  end

  ## Changesets

  def create_changeset(struct, attrs) do
    struct
    |> base_changeset(attrs)
    |> cast(attrs, [:book_id])
    |> validate_book_id()
    |> cast_assoc(:peers, with: &Transfers.Peer.create_money_transfer_changeset/2)
  end

  def update_changeset(struct, attrs) do
    struct
    |> base_changeset(attrs)
    |> cast_assoc(:peers, with: &Transfers.Peer.update_money_transfer_changeset/2)
  end

  defp base_changeset(struct, attrs) do
    struct
    |> cast(attrs, [:label, :amount, :type, :date, :tenant_id, :balance_params])
    |> validate_label()
    |> validate_required(:amount)
    |> validate_type()
    |> validate_tenant_id()
  end

  defp validate_label(changeset) do
    changeset
    |> validate_required(:label)
    |> validate_length(:label, min: 1, max: 255)
  end

  defp validate_type(changeset) do
    changeset
    |> validate_required(:type)
  end

  defp validate_book_id(changeset) do
    changeset
    |> validate_required(:book_id)
    |> foreign_key_constraint(:book_id)
  end

  defp validate_tenant_id(changeset) do
    changeset
    |> validate_required(:tenant_id)
    |> foreign_key_constraint(:tenant_id)
  end

  ## Queries

  def base_query do
    from __MODULE__, as: :money_transfer
  end

  def where_book_id(query, book_id) do
    from [money_transfer: money_transfer] in query,
      where: money_transfer.book_id == ^book_id
  end
end
