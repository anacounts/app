defmodule AnacountsAPI.Resolvers.Transfers do
  @moduledoc """
  Resolve queries and mutations from
  the `AnacountsAPI.Schema.TransfersTypes` module.
  """
  use AnacountsAPI, :resolver

  alias Anacounts.Accounts
  alias Anacounts.Transfers

  ## Queries

  def find_money_transfer(_parent, %{id: id}, %{context: %{current_user: user}}) do
    with {:ok, transfer} <- fetch_transfer(id),
         {:ok, _book} <- fetch_book(transfer.book_id, user) do
      {:ok, transfer}
    end
  end

  ## Mutations

  def do_create_money_transfer(
        _parent,
        %{attrs: %{book_id: book_id} = attrs},
        %{context: %{current_user: user}}
      ) do
    with {:ok, member} <- fetch_membership(book_id, user),
         :ok <- has_rights?(member, :handle_money_transfers) do
      Transfers.create_transfer(attrs)
    end
  end

  def do_create_money_transfer(_parent, _args, _resolution), do: not_logged_in()

  def do_update_money_transfer(
        _parent,
        %{transfer_id: transfer_id, attrs: attrs},
        %{context: %{current_user: user}}
      ) do
    with {:ok, transfer} <- fetch_transfer(transfer_id),
         {:ok, member} <- fetch_membership(transfer.book_id, user),
         :ok <- has_rights?(member, :handle_money_transfers) do
      Transfers.update_transfer(transfer, attrs)
    end
  end

  def do_update_money_transfer(_parent, _args, _resolution), do: not_logged_in()

  def do_delete_money_transfer(
        _parent,
        %{transfer_id: transfer_id},
        %{context: %{current_user: user}}
      ) do
    with {:ok, transfer} <- fetch_transfer(transfer_id),
         {:ok, member} <- fetch_membership(transfer.book_id, user),
         :ok <- has_rights?(member, :handle_money_transfers) do
      Transfers.delete_transfer(transfer)
    end
  end

  def do_delete_money_transfer(_parent, _args, _resolution), do: not_logged_in()

  defp fetch_book(book_id, user) do
    if book = Accounts.get_book_of_user(book_id, user) do
      {:ok, book}
    else
      {:error, :not_found}
    end
  end

  defp fetch_transfer(transfer_id) do
    if transfer = Transfers.get_transfer(transfer_id) do
      {:ok, transfer}
    else
      {:error, :not_found}
    end
  end

  defp fetch_membership(book_id, user) do
    if member = Accounts.get_membership(book_id, user) do
      {:ok, member}
    else
      {:error, :not_found}
    end
  end

  defp has_rights?(member, right) do
    if Accounts.Rights.member_has_right?(member, right) do
      :ok
    else
      {:error, :unauthorized}
    end
  end

  ## Field resolution

  def get_money_transfer_balance_params(
        %{balance_params: nil, book_id: book_id},
        _args,
        _resolution
      ) do
    book = Accounts.get_book!(book_id)
    {:ok, book.default_balance_params}
  end

  def get_money_transfer_balance_params(%{balance_params: balance_params}, _args, _resolution),
    do: {:ok, balance_params}

  # TODO rename field resolution functions to `get_xxx`

  def find_money_transfer_peers(transfer, _args, _resolution) do
    {:ok, Transfers.find_transfer_peers(transfer.id)}
  end

  ## External field resolution

  def find_book_transfers(book, _args, _resolution) do
    {:ok, Transfers.find_transfers_in_book(book.id)}
  end
end
