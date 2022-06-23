defmodule Anacounts.Transfers do
  @moduledoc """
  Context for money transfers.
  """

  alias Anacounts.Repo

  alias Anacounts.Accounts
  alias Anacounts.Auth
  alias Anacounts.Transfers.MoneyTransfer

  @spec create_transfer(Accounts.Book.t(), Auth.User.id(), map()) ::
          {:ok, MoneyTransfer.t()} | {:error, Ecto.Changeset.t()}
  def create_transfer(book_id, user_id, attrs) do
    MoneyTransfer.create_changeset(book_id, user_id, attrs)
    |> Repo.insert()
  end
end
