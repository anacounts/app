defmodule App.Transfers do
  @moduledoc """
  Context for money transfers.
  """

  alias App.Repo

  alias App.Transfers.MoneyTransfer
  alias App.Transfers.Peer

  ## Money transfer

  @doc """
  Gets a single money_transfer.

  Raises `Ecto.NoResultsError` if the Money transfer does not exist.

  ## Examples

      iex> get_money_transfer!(123)
      %MoneyTransfer{}

      iex> get_money_transfer!(-1)
      ** (Ecto.NoResultsError)

  """
  def get_money_transfer!(id), do: Repo.get!(MoneyTransfer, id)

  @doc """
  Gets a single money_transfer, if they belong to a book.

  Raises `Ecto.NoResultsError` if the Money transfer does not exist.

  ## Examples

      iex> get_money_transfer_of_book!(123)
      %MoneyTransfer{}

      iex> get_money_transfer_of_book!(-1)
      ** (Ecto.NoResultsError)
  """
  def get_money_transfer_of_book!(id, book_id),
    do: Repo.get_by!(MoneyTransfer, id: id, book_id: book_id)

  @doc """
  Creates a money_transfer.

  ## Examples

      iex> create_money_transfer(%{field: value})
      {:ok, %MoneyTransfer{}}

      iex> create_money_transfer(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_money_transfer(attrs \\ %{}) do
    %MoneyTransfer{}
    |> MoneyTransfer.create_changeset(attrs)
    # The `date` field default behaviour cannot be handled by Ecto
    # and is therefore handled by the database.
    # Make the database return its value.
    |> Repo.insert(returning: [:date])
  end

  @doc """
  Updates a money_transfer.

  ## Examples

      iex> update_money_transfer(money_transfer, %{field: new_value})
      {:ok, %MoneyTransfer{}}

      iex> update_money_transfer(money_transfer, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_money_transfer(%MoneyTransfer{} = money_transfer, attrs) do
    money_transfer
    # peers can be updated by the changeset
    |> Repo.preload(:peers)
    |> MoneyTransfer.update_changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a money_transfer.

  ## Examples

      iex> delete_money_transfer(money_transfer)
      {:ok, %MoneyTransfer{}}

      iex> delete_money_transfer(money_transfer)
      {:error, %Ecto.Changeset{}}

  """
  def delete_money_transfer(%MoneyTransfer{} = money_transfer) do
    Repo.delete(money_transfer)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking money_transfer changes.

  ## Examples

      iex> change_money_transfer(money_transfer)
      %Ecto.Changeset{data: %MoneyTransfer{}}

  """
  def change_money_transfer(%MoneyTransfer{} = money_transfer, attrs \\ %{}) do
    MoneyTransfer.update_changeset(money_transfer, attrs)
  end

  ## Peers

  @spec find_transfer_peers(MoneyTransfer.id()) :: [Peer.t()]
  def find_transfer_peers(transfer_id) do
    Peer.base_query()
    |> Peer.where_transfer_id(transfer_id)
    |> Repo.all()
  end

  # TODO I don't know where to put this now

  @spec find_transfers_in_book(Book.id()) :: [MoneyTransfer.t()]
  def find_transfers_in_book(book_id) do
    MoneyTransfer.base_query()
    |> MoneyTransfer.where_book_id(book_id)
    |> Repo.all()
  end
end
