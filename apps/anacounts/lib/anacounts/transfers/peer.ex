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
end
