defmodule Anacounts.Transfers do
  @moduledoc """
  Context for money transfers.
  """

  alias Anacounts.Repo

  alias Anacounts.Accounts
  alias Anacounts.Transfers.MoneyTransfer
  alias Anacounts.Transfers.Peer

  @spec get_transfer(MoneyTransfer.id()) :: MoneyTransfer.t() | nil
  def get_transfer(id) do
    Repo.get(MoneyTransfer, id)
  end

  @spec find_transfers_in_book(Book.id()) :: [MoneyTransfer.t()]
  def find_transfers_in_book(book_id) do
    MoneyTransfer.base_query()
    |> MoneyTransfer.where_book_id(book_id)
    |> Repo.all()
  end

  @spec find_transfer_peers(MoneyTransfer.id()) :: [Peer.t()]
  def find_transfer_peers(transfer_id) do
    Peer.base_query()
    |> Peer.where_transfer_id(transfer_id)
    |> Repo.all()
  end

  @spec create_transfer(Accounts.Book.t(), Accounts.BookMember.id(), map()) ::
          {:ok, MoneyTransfer.t()} | {:error, Ecto.Changeset.t()}
  def create_transfer(book_id, member_id, attrs) do
    MoneyTransfer.create_changeset(book_id, member_id, attrs)
    # The `date` field default behaviour cannot be handled by Ecto
    # and is therefore handled by the database.
    # Make the database return its value.
    |> Repo.insert(returning: [:date])
  end

  @spec update_transfer(MoneyTransfer.t(), map()) ::
          {:ok, MoneyTransfer.t()} | {:error, Ecto.Changeset.t()}
  def update_transfer(transfer, attrs) do
    transfer_with_preloads = Repo.preload(transfer, :peers)

    MoneyTransfer.update_changeset(transfer_with_preloads, attrs)
    |> Repo.update()
  end

  @spec delete_transfer(MoneyTransfer.t()) ::
          {:ok, MoneyTransfer.t()} | {:error, Ecto.Changeset.t()}
  def delete_transfer(transfer) do
    Repo.delete(transfer)
  end
end
