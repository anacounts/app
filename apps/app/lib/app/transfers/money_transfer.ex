defmodule App.Transfers.MoneyTransfer do
  @moduledoc """
  Entity representing money transfers. This includes both payments,
  incomes and reimbursements.
  """

  use Ecto.Schema

  import Ecto.Changeset
  import Ecto.Query

  alias App.Balance.TransferParams
  alias App.Books.Book
  alias App.Books.BookMember
  alias App.Transfers.Peer

  @type id :: integer()
  @type t :: %__MODULE__{
          id: id(),
          label: String.t(),
          amount: Money.t(),
          type: type(),
          date: Date.t(),
          book: Book.t(),
          tenant: BookMember.t(),
          balance_params: TransferParams.t(),
          peers: [Peer.t()],
          total_peer_weight: Decimal.t(),
          inserted_at: DateTime.t(),
          updated_at: DateTime.t()
        }

  # TODO rename transfer.type to transfer.kind

  @type type :: :payment | :income | :reimbursement
  @transfer_types [:payment, :income, :reimbursement]

  schema "money_transfers" do
    field :label, :string
    field :amount, Money.Ecto.Composite.Type
    field :type, Ecto.Enum, values: @transfer_types
    field :date, :date, read_after_writes: true

    belongs_to :book, Book
    belongs_to :tenant, BookMember

    # balance
    field :balance_params, TransferParams

    has_many :peers, Peer,
      foreign_key: :transfer_id,
      on_replace: :delete_if_exists

    # The current peer is used in some operations, like when updating the revenues,
    # in the "transfers" step, to know the link between the current member and the transfer.
    field :current_peer, :map, virtual: true

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

  @doc """
  Changeset for creating a reimbursement kind of money transfer.
  """
  def reimbursement_changeset(struct, attrs) do
    struct
    |> cast(attrs, [:label, :amount, :date, :tenant_id])
    |> validate_label()
    |> validate_amount()
    |> cast_assoc(:peers, with: &Peer.update_money_transfer_changeset/2)
    |> validate_reimbursement_peers()
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
    |> validate_inclusion(:type, [:payment, :income])
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

  defp validate_reimbursement_peers(changeset) do
    tenant_id = Ecto.Changeset.fetch_field!(changeset, :tenant_id)

    changeset
    |> validate_change(:peers, fn :peers, peers ->
      case peers do
        [_one_peer] -> []
        _peers -> raise Ecto.ChangeError, "A reimbursement must have exactly one peer"
      end
    end)
    |> validate_change(:peers, fn :peers, [peer] ->
      peer_member_id = Ecto.Changeset.fetch_field!(peer, :member_id)

      if peer_member_id == tenant_id,
        do: [tenant_id: "cannot be the same as the debtor"],
        else: []
    end)
  end

  ## Queries

  # create a simple query with named binding
  defp base_query do
    from __MODULE__, as: :money_transfer
  end

  @doc """
  Get all money transfers within a book.
  """
  @spec transfers_of_book_query(Book.t()) :: Ecto.Query.t()
  def transfers_of_book_query(book) do
    from [money_transfer: money_transfer] in base_query(),
      where: money_transfer.book_id == ^book.id
  end
end
