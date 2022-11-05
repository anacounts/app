defmodule App.Transfers.Peers.Peer do
  @moduledoc """
  Entity linking money transfers to users.
  """

  use Ecto.Schema
  import Ecto.Changeset

  alias App.Books.Members.BookMember
  alias App.Transfers

  @type id :: integer()
  @type t :: %__MODULE__{
          id: id(),
          transfer: Transfers.MoneyTransfer.t(),
          member: BookMember.t(),
          weight: Decimal.t()
        }

  schema "transfers_peers" do
    belongs_to :transfer, Transfers.MoneyTransfer
    belongs_to :member, BookMember

    field :weight, :decimal, default: Decimal.new(1)
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
end
