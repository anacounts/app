defmodule Anacounts.Accounts.Balance.GraphTest do
  use Anacounts.DataCase, async: true

  import Anacounts.Accounts.Balance.Graph

  doctest Anacounts.Accounts.Balance.Graph

  describe "from_peer_balances/1" do
    defp peer_balance(from, to, amount) do
      %{from: from, to: to, amount: Money.new(amount, :EUR), transfer_id: nil}
    end

    defp vertex(from, to, weight) do
      %{from: from, to: to, weight: Money.new(weight, :EUR)}
    end

    test "returns the matching graph" do
      graph =
        from_peer_balances([
          peer_balance(?A, ?B, 400),
          peer_balance(?B, ?C, -700),
          peer_balance(?C, ?A, -100),
          peer_balance(?B, ?A, 500)
        ])

      assert graph == {
               MapSet.new([?A, ?B, ?C]),
               [
                 vertex(?B, ?A, 500),
                 vertex(?C, ?A, -100),
                 vertex(?B, ?C, -700),
                 vertex(?A, ?B, 400)
               ]
             }
    end
  end
end
