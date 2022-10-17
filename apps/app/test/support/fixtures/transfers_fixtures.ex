defmodule App.TransfersFixtures do
  @moduledoc """
  Fixtures for the `App.Transfers` context
  """

  alias App.Transfers

  def money_transfer_attributes(attrs) do
    Enum.into(attrs, %{
      label: "This is a money transfer",
      amount: Money.new(1799, :EUR),
      date: ~D[2022-06-23],
      type: :payment,
      balance_params: nil,
      peers: []
    })
  end

  def money_transfer_fixture(attrs \\ %{}) do
    {:ok, transfer} =
      attrs
      |> money_transfer_attributes()
      |> Transfers.create_money_transfer()

    transfer
  end
end
