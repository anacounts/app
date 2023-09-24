defmodule App.TransfersFixtures do
  @moduledoc """
  Fixtures for the `App.Transfers` context
  """

  import App.BalanceFixtures

  alias App.Books.Book
  alias App.Transfers

  def money_transfer_attributes(attrs \\ %{}) do
    Enum.into(attrs, %{
      label: "This is a money transfer",
      amount: Money.new!(:EUR, 1799),
      date: ~D[2022-06-23],
      type: :payment,
      balance_params: transfer_params_attributes(),
      peers: []
    })
  end

  def money_transfer_fixture(%Book{} = book, attrs \\ %{}) do
    {:ok, transfer} = Transfers.create_money_transfer(book, money_transfer_attributes(attrs))
    transfer
  end
end
