defmodule Anacounts.Transfers.MoneyTransfer do
  @moduledoc """
  Entity representing money transfers. This includes both payments,
  incomes and reimbursements.
  """

  use Ecto.Schema

  import Ecto.Changeset
  import Ecto.Query

  alias Anacounts.Accounts
  alias Anacounts.Auth
  alias Anacounts.Transfers

  # the types
  @transfer_types [:payment, :income, :reimbursement]

  @type id :: integer()
  @type t :: %__MODULE__{
          id: id(),
          amount: Money.t(),
          type: :payment | :income | :reimbursement,
          book: Accounts.Book.t(),
          holder: Auth.User.t(),
          peers: Transfers.Peer.t()
        }

  schema "transfers_money_transfers" do
    field :amount, Money.Ecto.Composite.Type
    field :type, Ecto.Enum, values: @transfer_types
    field :date, :utc_datetime

    belongs_to :book, Accounts.Book
    belongs_to :holder, Auth.User

    has_many :peers, Transfers.Peer, foreign_key: :transfer_id

    timestamps()
  end
end
