defmodule App.Transfers do
  @moduledoc """
  Context for money transfers.
  """

  import Ecto.Query
  alias App.Repo

  alias App.Auth.User
  alias App.Books.Book
  alias App.Books.BookMember
  alias App.Books.Members
  alias App.Books.Rights
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

      iex> list_transfers_of_book(123)
      [%MoneyTransfer{}, ...]

  """
  @spec list_transfers_of_book(Book.id()) :: [MoneyTransfer.t()]
  def list_transfers_of_book(book_id) do
    base_query()
    |> where_book_id(book_id)
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
        Members.base_query()
        |> Members.with_display_name_query()
    )
  end

  @doc """
  Creates a money_transfer.

  ## Examples

      iex> create_money_transfer(book, %{field: value})
      {:ok, %MoneyTransfer{}}

      iex> create_money_transfer(book, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_money_transfer(%Book{} = book, attrs \\ %{}) do
    %MoneyTransfer{book_id: book.id}
    |> MoneyTransfer.changeset(attrs)
    |> MoneyTransfer.with_peers(&Peer.create_money_transfer_changeset/2)
    # The `date` field default behaviour cannot be handled by Ecto
    # and is therefore handled by the database.
    # Make the database return its value.
    |> Repo.insert(returning: [:date])
  end

  @doc """
  Updates a money_transfer.

  ## Examples

      iex> update_money_transfer(money_transfer, user, %{field: new_value})
      {:ok, %MoneyTransfer{}}

      iex> update_money_transfer(money_transfer, user, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

      iex> update_money_transfer(money_transfer, not_allowed_user, %{field: new_value})
      {:error, :unauthorized}

  """
  @spec update_money_transfer(MoneyTransfer.t(), User.t(), map()) ::
          {:ok, MoneyTransfer.t()} | {:error, Ecto.Changeset.t()} | {:error, :unauthorized}
  def update_money_transfer(%MoneyTransfer{} = money_transfer, %User{} = user, attrs) do
    if can_handle_transfers?(money_transfer.book_id, user.id) do
      money_transfer
      # peers can be updated by the changeset
      |> Repo.preload(:peers)
      |> MoneyTransfer.changeset(attrs)
      |> MoneyTransfer.with_peers(&Peer.update_money_transfer_changeset/2)
      |> Repo.update()
    else
      {:error, :unauthorized}
    end
  end

  @doc """
  Deletes a money_transfer.

  ## Examples

      iex> delete_money_transfer(money_transfer)
      {:ok, %MoneyTransfer{}}

      iex> delete_money_transfer(money_transfer)
      {:error, %Ecto.Changeset{}}

  """
  def delete_money_transfer(%MoneyTransfer{} = money_transfer, %User{} = user) do
    if can_handle_transfers?(money_transfer.book_id, user.id) do
      Repo.delete(money_transfer)
    else
      {:error, :unauthorized}
    end
  end

  defp can_handle_transfers?(book_id, user_id) do
    if member = Members.get_membership(book_id, user_id),
      do: Rights.can_member_handle_money_transfers?(member),
      else: false
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

  ## Examples

      iex> amount(%MoneyTransfer{amount: 100, type: :payment})
      100

      iex> amount(%MoneyTransfer{amount: 100, type: :income})
      -100

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
