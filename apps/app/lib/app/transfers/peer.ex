defmodule App.Transfers.Peer do
  @moduledoc """
  Entity linking money transfers to users.
  """

  use Ecto.Schema
  import Ecto.Changeset

  alias App.Balance.BalanceConfig
  alias App.Books.BookMember
  alias App.Transfers.MoneyTransfer

  @type id :: integer()
  @type t :: %__MODULE__{
          id: id(),
          transfer: MoneyTransfer.t(),
          member: BookMember.t(),
          weight: Decimal.t(),
          user_balance_config: BalanceConfig.t() | nil,
          balance_config: BalanceConfig.t() | nil,
          balance_config_id: BalanceConfig.id() | nil,
          total_weight: Decimal.t() | nil
        }

  schema "transfers_peers" do
    belongs_to :transfer, MoneyTransfer
    belongs_to :member, BookMember

    field :weight, :decimal, default: Decimal.new(1)

    has_one :user_balance_config, through: [:member, :user, :balance_config]
    belongs_to :balance_config, BalanceConfig
    # The sum of all the peer weight. Depends on the transfer balance means
    field :total_weight, :decimal, virtual: true
  end

  def create_money_transfer_changeset(struct, attrs) do
    struct
    |> cast(attrs, [:member_id, :weight])
    |> validate_member_id()
    |> validate_unique_by_transfer_and_member()
  end

  def update_money_transfer_changeset(struct, attrs)

  # new peer built, must set a `member_id`
  def update_money_transfer_changeset(%{id: nil} = struct, attrs) do
    struct
    |> cast(attrs, [:member_id, :weight])
    |> validate_member_id()
    |> validate_unique_by_transfer_and_member()
  end

  # updating an existing peer, cannot change `member_id`
  def update_money_transfer_changeset(struct, attrs) do
    struct
    |> cast(attrs, [:weight])
    |> validate_unique_by_transfer_and_member()
  end

  defp validate_member_id(changeset) do
    changeset
    |> validate_required(:member_id)
    |> foreign_key_constraint(:member_id)
  end

  defp validate_unique_by_transfer_and_member(changeset) do
    changeset
    |> unique_constraint([:transfer_id, :member_id],
      message: "member is already a peer of this money transfer",
      error_key: :member_id
    )
  end

  @doc """
  Changeset for updating the balance config of a book member.
  """
  @spec balance_config_changeset(t(), map()) :: Ecto.Changeset.t()
  def balance_config_changeset(struct, attrs) do
    struct
    |> cast(attrs, [:balance_config_id])
    |> validate_balance_config_id()
  end

  defp validate_balance_config_id(changeset) do
    changeset
    |> foreign_key_constraint(:balance_config_id)
  end
end
