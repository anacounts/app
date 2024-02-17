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

  ## Database getters

  @doc """
  Gets a single money_transfer.

  Raises `Ecto.NoResultsError` if the Money transfer does not exist.
  """
  def get_money_transfer!(id), do: Repo.get!(MoneyTransfer, id)

  @doc """
  Gets a single money_transfer, if they belong to a book.

  Raises `Ecto.NoResultsError` if the Money transfer does not exist.
  """
  def get_money_transfer_of_book!(id, book_id),
    do: Repo.get_by!(MoneyTransfer, id: id, book_id: book_id)

  @doc """
  Find all money transfers of a book.

  The result may be filtered by passing a options.

  ## Options

  - `:filters` - a map of filters to apply to the query. See the `Filters` section below.
  - `:offset` - the offset of the query
  - `:limit` - the limit of the query

  ## Filters

  - `:sort_by` - the field to sort by, one of :most_recent, :oldest, :last_created or
    :first_created
  - `:tenanted_by` - the tenancy of the transfer, one of :anyone, a member id or
    `{:not, member_id}`
  """
  @spec list_transfers_of_book(Book.t(), Keyword.t()) :: [MoneyTransfer.t()]
  def list_transfers_of_book(%Book{} = book, opts \\ []) do
    filters = Keyword.get(opts, :filters, %{})
    offset = Keyword.get(opts, :offset, 0)
    limit = Keyword.get(opts, :limit, 25)

    MoneyTransfer.transfers_of_book_query(book)
    |> filter_money_transfers_query(filters)
    |> paginate_query(offset, limit)
    |> Repo.all()
  end

  @doc """
  Find all money transfers related to book members.
  """
  @spec list_transfers_of_members([BookMember.t()]) :: [MoneyTransfer.t()]
  def list_transfers_of_members(members) do
    members_id = Enum.map(members, fn %BookMember{} = member -> member.id end)

    from(money_transfer in MoneyTransfer,
      join: peer in assoc(money_transfer, :peers),
      where: peer.member_id in ^members_id,
      distinct: true
    )
    |> Repo.all()
  end

  ## Filters

  @filters_default %{
    sort_by: :most_recent,
    tenanted_by: :anyone
  }
  @filters_types %{
    sort_by:
      Ecto.ParameterizedType.init(Ecto.Enum,
        values: [:most_recent, :oldest, :last_created, :first_created]
      ),
    # Values are `:anyone`, `member_id` or `{:not, member_id}`
    tenanted_by: :any
  }

  defp filter_money_transfers_query(query, raw_filters) do
    filters =
      {@filters_default, @filters_types}
      |> Ecto.Changeset.cast(raw_filters, Map.keys(@filters_types))
      |> Ecto.Changeset.apply_changes()

    query
    |> sort_money_transfers_by(filters[:sort_by])
    |> filter_money_transfers_by_tenancy(filters[:tenanted_by])
  end

  defp sort_money_transfers_by(query, :most_recent),
    do: from([money_transfer: money_transfer] in query, order_by: [desc: money_transfer.date])

  defp sort_money_transfers_by(query, :oldest),
    do: from([money_transfer: money_transfer] in query, order_by: [asc: money_transfer.date])

  defp sort_money_transfers_by(query, :last_created),
    do:
      from([money_transfer: money_transfer] in query,
        order_by: [desc: money_transfer.inserted_at]
      )

  defp sort_money_transfers_by(query, :first_created),
    do:
      from([money_transfer: money_transfer] in query, order_by: [asc: money_transfer.inserted_at])

  defp filter_money_transfers_by_tenancy(query, :anyone), do: query

  defp filter_money_transfers_by_tenancy(query, {:not, member_id}),
    do:
      from([money_transfer: money_transfer] in query,
        where: money_transfer.tenant_id != ^member_id
      )

  defp filter_money_transfers_by_tenancy(query, member_id),
    do:
      from([money_transfer: money_transfer] in query,
        where: money_transfer.tenant_id == ^member_id
      )

  ## Pagination

  defp paginate_query(query, offset, limit) do
    query
    |> limit(^limit)
    |> offset(^offset)
  end

  ## Amount summary

  @typep amount_summary :: %{
           type: MoneyTransfer.type(),
           amount: Money.t(),
           count: non_neg_integer()
         }

  @doc """
  Returns the total amount of money transfers linked to a book, grouped by type.

  The `:reimbursement` type is not included. If a book has no money transfers of a type,
  the amount for this type will be `Money.zero(:EUR)` and the count is `0`.
  """
  @spec amounts_summary_for_book(Book.t()) :: %{MoneyTransfer.type() => amount_summary()}
  def amounts_summary_for_book(book) do
    amounts_summary_query()
    |> where([money_transfer: money_transfer], money_transfer.book_id == ^book.id)
    |> Repo.all()
    |> Map.new(&{&1.type, &1})
    |> fill_grouped_amounts_missing_types()
  end

  @doc """
  Returns the total amount of money transfers tenanted by a member, grouped by type.

  The `:reimbursement` type is not included. If a book has no money transfers of a type,
  the amount for this type will be `Money.zero(:EUR)` and the count is `0`.
  """
  @spec amounts_summary_for_tenant(BookMember.t()) :: %{MoneyTransfer.type() => amount_summary()}
  def amounts_summary_for_tenant(member) do
    amounts_summary_query()
    |> where([money_transfer: money_transfer], money_transfer.tenant_id == ^member.id)
    |> Repo.all()
    |> Map.new(&{&1.type, &1})
    |> fill_grouped_amounts_missing_types()
  end

  defp amounts_summary_query do
    from money_transfer in MoneyTransfer,
      as: :money_transfer,
      where: money_transfer.type != :reimbursement,
      select: %{
        type: money_transfer.type,
        amount: sum(money_transfer.amount),
        count: count(money_transfer.id)
      },
      group_by: money_transfer.type
  end

  defp fill_grouped_amounts_missing_types(grouped_amounts) do
    Enum.reduce([:payment, :income], grouped_amounts, fn type, amounts ->
      Map.put_new_lazy(amounts, type, fn ->
        %{type: type, amount: Money.zero(:EUR), count: 0}
      end)
    end)
  end

  ## Preloads

  @doc """
  Preloads the tenant of one or a list of money transfers.
  Includes the display name of the tenant.
  """
  @spec with_tenant([MoneyTransfer.t()]) :: [MoneyTransfer.t()]
  def with_tenant(transfers) do
    Repo.preload(transfers,
      tenant:
        BookMember.base_query()
        |> BookMember.select_display_name()
    )
  end

  ## CRUD

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
  """
  def change_money_transfer(%MoneyTransfer{} = money_transfer, attrs \\ %{}) do
    money_transfer
    |> MoneyTransfer.changeset(attrs)
    |> MoneyTransfer.with_peers(&Peer.update_money_transfer_changeset/2)
  end

  ## Status/fields

  # TODO Rework, a :payment should have a negative amount since it appears as negative to the user

  @doc """
  Retrieves the amount of money a money transfer costs or provides.
  """
  @spec amount(MoneyTransfer.t()) :: Money.t()
  def amount(money_transfer)
  def amount(%MoneyTransfer{type: :payment} = money_transfer), do: money_transfer.amount
  def amount(%MoneyTransfer{} = money_transfer), do: Money.mult!(money_transfer.amount, -1)
end
