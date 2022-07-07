defmodule Anacounts.TransfersFixtures do
  @moduledoc """
  Fixtures for the `Transfer` context
  """

  alias Anacounts.Transfers

  def valid_money_transfer_label, do: "This is a money transfer"
  def valid_money_transfer_amount, do: Money.new(1799, :EUR)
  def valid_money_transfer_date, do: ~U[2022-06-23 14:02:51Z]
  def valid_money_transfer_type, do: :payment

  def valid_money_transfer_attributes(attrs) do
    Enum.into(attrs, %{
      label: valid_money_transfer_label(),
      amount: valid_money_transfer_amount(),
      date: valid_money_transfer_date(),
      type: valid_money_transfer_type(),
      peers: []
    })
  end

  def money_transfer_fixture(attrs \\ %{}) do
    valid_attrs = valid_money_transfer_attributes(attrs)
    {:ok, transfer} = Transfers.create_transfer(valid_attrs)
    transfer
  end

  def setup_money_transfer_fixture(%{book: book, book_member: book_member} = context) do
    Map.put(
      context,
      :money_transfer,
      money_transfer_fixture(book_id: book.id, tenant_id: book_member.id)
    )
  end
end
