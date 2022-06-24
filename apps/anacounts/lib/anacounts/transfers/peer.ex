defmodule Anacounts.Transfers.Peer do
  @moduledoc """
  Entity linking money transfers to users.
  """

  use Ecto.Schema
  import Ecto.Changeset

  alias Anacounts.Auth
  alias Anacounts.Transfers

  @type id :: integer()
  @type t :: %__MODULE__{
          id: id(),
          transfer: Transfers.MoneyTransfer.t(),
          user: Auth.User.t(),
          weight: Decimal.t()
        }

  schema "transfers_peers" do
    belongs_to :transfer, Transfers.MoneyTransfer
    belongs_to :user, Auth.User

    field :weight, :decimal, default: Decimal.new(1)
  end

  def create_money_transfer_changeset(struct, attrs) do
    struct
    |> cast(attrs, [:transfer_id, :user_id, :weight])
    |> foreign_key_constraint(:transfer_id)
    |> validate_user_id()
    |> validate_unique_transfer_and_user_id()
  end

  def update_money_transfer_changeset(struct, attrs)

  # new peer built, must set a `user_id`
  def update_money_transfer_changeset(%{id: nil} = struct, attrs) do
    struct
    |> cast(attrs, [:user_id, :weight])
    |> validate_user_id()
    |> validate_unique_transfer_and_user_id()
  end

  # updating an existing peer, cannot change `user_id`
  def update_money_transfer_changeset(struct, attrs) do
    struct
    |> cast(attrs, [:weight])
    |> validate_unique_transfer_and_user_id()
  end

  defp validate_user_id(changeset) do
    changeset
    |> validate_required(:user_id)
    |> foreign_key_constraint(:user_id)
  end

  defp validate_unique_transfer_and_user_id(changeset) do
    changeset
    |> unique_constraint([:transfer_id, :user_id],
      message: "user is already a peer of this money transfer",
      error_key: :user_id
    )
  end
end
