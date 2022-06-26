defmodule AnacountsAPI.Schema.TransfersTypes do
  @moduledoc """
  Objects related to the `Anacounts.Auth` module.
  """

  use Absinthe.Schema.Notation

  alias AnacountsAPI.Resolvers

  ## Entities

  @desc """
  A money transfer is any payment, income, reimbursement in a book.

  It is owned by a user called the holder. They may earn or pay
  depending on the type of the transfer.
  """
  object :money_transfer do
    field(:id, :id)

    field(:amount, :money)
    field(:type, :money_transfer_type)
    field(:date, :datetime)

    field(:book, :book) do
      resolve(&Resolvers.Accounts.find_money_transfer_book/3)
    end

    field(:holder, :book_member) do
      resolve(&Resolvers.Accounts.find_money_transfer_holder/3)
    end

    field(:peers, list_of(:transfer_peer)) do
      resolve(&Resolvers.Transfers.find_money_transfer_peers/3)
    end
  end

  @desc """
  MoneyTransferType is an enumeration representing the type of a MoneyTransfer.
  """
  # TODO Document the differences between types
  enum :money_transfer_type do
    value(:payment)
    value(:income)
    value(:reimbursement)
  end

  @doc """
  A peer in a transfer.
  """
  object :transfer_peer do
    field(:id, :id)
    field(:weight, :decimal)

    field(:member, :book_member) do
      resolve(&Resolvers.Accounts.find_transfer_peer_user/3)
    end
  end

  ## Queries

  object :transfers_queries do
  end

  ## Mutations

  object :transfers_mutations do
    @desc "Create a new money transfer"
    field :create_money_transfer, :money_transfer do
      arg(:attrs, non_null(:money_transfer_creation_input))

      resolve(&Resolvers.Transfers.do_create_money_transfer/3)
    end

    @desc "Update an existing money transfer"
    field :update_money_transfer, :money_transfer do
      arg(:transfer_id, non_null(:id))
      arg(:attrs, non_null(:money_transfer_update_input))

      resolve(&Resolvers.Transfers.do_update_money_transfer/3)
    end
  end

  ## Input objects

  ### Creation

  @desc """
  Input used to create a money transfer.
  """
  input_object :money_transfer_creation_input do
    field(:book_id, non_null(:id))
    field(:amount, non_null(:money))
    field(:type, non_null(:money_transfer_type))
    field(:date, :datetime)

    field(:peers, list_of(:transfer_peer_creation_input))
  end

  @desc """
  Input used to create a peer in a money transfer
  """
  input_object :transfer_peer_creation_input do
    field(:member_id, non_null(:id))
    field(:weight, :decimal)
  end

  ### Update

  @desc """
  Input used to update a money transfer.
  """
  input_object :money_transfer_update_input do
    field(:amount, :money)
    field(:type, :money_transfer_type)
    field(:date, :datetime)

    field(:peers, list_of(:transfer_peer_update_input))
  end

  @desc """
  Input used in the update of a money transfer.
  This object can either mean to update an existing peer if `peerId` is set,
  or create a new peer if it is not.
  """
  input_object :transfer_peer_update_input do
    field(:peer_id, :id)
    field(:member_id, non_null(:id))

    field(:weight, :decimal)
  end
end
