defmodule Anacounts.Transfers do
  @moduledoc """
  Context for money transfers.
  """

  alias Anacounts.Repo

  alias Anacounts.Accounts
  alias Anacounts.Auth
  alias Anacounts.Transfers.MoneyTransfer

  @spec find_transfers_in_book(Book.id()) :: [MoneyTransfer.t()]
  def find_transfers_in_book(book_id) do
    MoneyTransfer.base_query()
    |> MoneyTransfer.where_book_id(book_id)
    |> Repo.all()
  end

  @spec create_transfer(Accounts.Book.t(), Auth.User.id(), map()) ::
          {:ok, MoneyTransfer.t()} | {:error, Ecto.Changeset.t()}
  def create_transfer(book_id, user_id, attrs) do
    MoneyTransfer.create_changeset(book_id, user_id, attrs)
    |> Repo.insert()
  end

  @spec update_transfer(MoneyTransfer.t(), map()) ::
          {:ok, MoneyTransfer.t()} | {:error, Ecto.Changeset.t()}
  def update_transfer(transfer, attrs) do
    transfer_with_preloads = Repo.preload(transfer, :peers)

    MoneyTransfer.update_changeset(transfer_with_preloads, attrs)
    |> Repo.update()
  end
end
