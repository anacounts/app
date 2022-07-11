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

  describe "contract_vertices/1" do
    test "if 1 node graph, removes all vertices" do
      input =
        {MapSet.new([?A]),
         [
           vertex(?A, ?A, 1),
           vertex(?A, ?A, 2),
           vertex(?A, ?A, 3)
         ]}

      output = contract_vertices(input)

      assert output == {MapSet.new([?A]), []}
    end

    test "reduce graph to minimum amount of vertices" do
      input =
        {MapSet.new([?A, ?B, ?C, ?D]),
         [
           vertex(?A, ?B, 1),
           vertex(?B, ?C, 2),
           vertex(?C, ?D, 3),
           vertex(?A, ?D, 4),
           vertex(?C, ?A, 5)
         ]}

      output = contract_vertices(input)

      assert output ==
               {MapSet.new([?A, ?B, ?C, ?D]), [vertex(?B, ?D, 1), vertex(?C, ?D, 6)]}
    end

    test "correctly reduces with negative weight" do
      input =
        {MapSet.new([?A, ?B]),
         [
           vertex(?A, ?B, -6),
           vertex(?A, ?B, 3),
           vertex(?B, ?A, 9),
           vertex(?A, ?B, -2),
           vertex(?B, ?A, 1)
         ]}

      output = contract_vertices(input)

      assert output ==
               {MapSet.new([?A, ?B]), [vertex(?B, ?A, 15)]}
    end

    test "drops redundant vertices" do
      input =
        {MapSet.new([?A, ?B, ?C, ?D, ?E]),
         [
           vertex(?D, ?A, 4),
           vertex(?D, ?B, 4),
           vertex(?D, ?C, 4),
           vertex(?D, ?D, 4),
           vertex(?D, ?E, 4),
           vertex(?B, ?A, 3),
           vertex(?B, ?B, 3),
           vertex(?B, ?C, 6)
         ]}

      output = contract_vertices(input)

      assert output ==
               {MapSet.new([?A, ?B, ?C, ?D, ?E]),
                [
                  vertex(?B, ?C, 5),
                  vertex(?D, ?A, 7),
                  vertex(?D, ?C, 5),
                  vertex(?D, ?E, 4)
                ]}
    end
  end
end
