defmodule App.Transfers do
  @moduledoc """
  Context for money transfers.
  """

  import Ecto.Query
  alias App.Repo

  alias App.Books.Book
  alias App.Books.BookMember
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
  Find all money transfers of a book.

  ## Examples

      iex> list_transfers_of_book(book)
      [%MoneyTransfer{}, ...]

  """
  @spec list_transfers_of_book(Book.t()) :: [MoneyTransfer.t()]
  def list_transfers_of_book(%Book{} = book) do
    base_query()
    |> where_book_id(book.id)
    |> order_by(desc: :date)
    |> Repo.all()
  end

  @doc """
  Find all money transfers related to book members.

  ## Examples

      iex> list_transfers_of_members([member1, member2])
      [%MoneyTransfer{}, ...]

  """
  @spec list_transfers_of_members([BookMember.t()]) :: [MoneyTransfer.t()]
  def list_transfers_of_members(members) do
    members_id = Enum.map(members, fn %BookMember{} = member -> member.id end)

    base_query()
    |> join_peers()
    |> where([peer: peer], peer.member_id in ^members_id)
    |> distinct(true)
    |> Repo.all()
  end

  @doc """
  Preloads the tenant of one or a list of money transfers.
  Includes the display name of the tenant.

  ## Examples

      iex> with_tenant(money_transfer)
      %MoneyTransfer{tenant: %BookMember{}}

      iex> with_tenant([money_transfer_1, money_transfer_2])
      [%MoneyTransfer{tenant: %BookMember{}}, %MoneyTransfer{tenant: %BookMember{}}]

  """
  @spec with_tenant([MoneyTransfer.t()]) :: [MoneyTransfer.t()]
  def with_tenant(transfers) do
    Repo.preload(transfers,
      tenant:
        BookMember.base_query()
        |> BookMember.select_display_name()
    )
  end

  @doc """
  Creates a money_transfer.
  """
  @spec create_money_transfer(Book.t(), map()) ::
          {:ok, MoneyTransfer.t()} | {:error, Ecto.Changeset.t()}
  def create_money_transfer(%Book{} = book, attrs \\ %{}) do
    %MoneyTransfer{book_id: book.id}
    |> MoneyTransfer.changeset(attrs)
    |> MoneyTransfer.with_peers(&Peer.create_money_transfer_changeset/2)
    |> link_balance_config_to_peers_changeset()
    |> Repo.insert()
  end

  defp link_balance_config_to_peers_changeset(changeset) do
    case Ecto.Changeset.fetch_change(changeset, :peers) do
      {:ok, peers_changeset} ->
        peers =
          changeset
          |> Ecto.Changeset.fetch_field!(:peers)
          # Members are required to fetch their balance config id
          |> Repo.preload(member: from(BookMember, select: [:balance_config_id]))

        balance_config_id_by_member_id =
          Map.new(peers, fn peer -> {peer.member_id, peer.member.balance_config_id} end)

        peers_changeset_with_balance_config =
          Enum.map(peers_changeset, fn peer_changeset ->
            member_id = Ecto.Changeset.fetch_field!(peer_changeset, :member_id)
            balance_config_id = balance_config_id_by_member_id[member_id]
            Ecto.Changeset.put_change(peer_changeset, :balance_config_id, balance_config_id)
          end)

        Ecto.Changeset.put_assoc(changeset, :peers, peers_changeset_with_balance_config)

      _ ->
        changeset
    end
  end

  @doc """
  Updates a money_transfer.
  """
  @spec update_money_transfer(MoneyTransfer.t(), map()) ::
          {:ok, MoneyTransfer.t()} | {:error, Ecto.Changeset.t()}
  def update_money_transfer(%MoneyTransfer{} = money_transfer, attrs) do
    money_transfer
    # peers can be updated by the changeset
    |> Repo.preload(:peers)
    |> MoneyTransfer.changeset(attrs)
    |> MoneyTransfer.with_peers(&Peer.update_money_transfer_changeset/2)
    |> Repo.update()
  end

  @doc """
  Deletes a money_transfer.
  """
  @spec delete_money_transfer(MoneyTransfer.t()) ::
          {:ok, MoneyTransfer.t()} | {:error, Ecto.Changeset.t()}
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
    money_transfer
    |> MoneyTransfer.changeset(attrs)
    |> MoneyTransfer.with_peers(&Peer.update_money_transfer_changeset/2)
  end

  # TODO Rework, a :payment should have a negative amount since it appears as negative to the user

  @doc """
  Retrieves the amount of money a money transfer costs or provides.
  """
  @spec amount(MoneyTransfer.t()) :: Money.t()
  def amount(money_transfer)
  def amount(%MoneyTransfer{type: :payment} = money_transfer), do: money_transfer.amount
  def amount(%MoneyTransfer{} = money_transfer), do: Money.neg(money_transfer.amount)

  ## Queries

  defp base_query do
    from MoneyTransfer, as: :money_transfer
  end

  defp join_peers(query, qual \\ :inner) do
    with_named_binding(query, :peer, fn query ->
      join(query, qual, [money_transfer: transfer], peer in assoc(transfer, :peers), as: :peer)
    end)
  end

  defp where_book_id(query, book_id) do
    from [money_transfer: money_transfer] in query,
      where: money_transfer.book_id == ^book_id
  end
end
