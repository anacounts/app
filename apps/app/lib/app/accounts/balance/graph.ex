defmodule App.Accounts.Balance.Graph do
  @moduledoc """
  A weighted graph representation of the peer balances.

  Expose methods to manipulate the graph, including optimizing
  the graph to a minimal graph.
  """

  alias App.Accounts
  alias App.Accounts.Balance

  @type t :: {MapSet.t(point()), [vertex()]}

  # a node in the graph
  @typep point :: Accounts.BookMember.id()

  # a link between two points in the graph
  @typep vertex :: %{from: point(), to: point(), weight: weight()}

  # the weight of a vertex
  @typep weight :: Money.t()

  @doc """
  For each node, add the outgoing vertexes and substract the incoming vertexes weights.
  This gives a summary of each nodes incoming and outgoing weight.

  ## Examples

      iex> nodes = MapSet.new([?A, ?B])
      iex> vertices = [%{from: ?A, to: ?B, weight: Money.new(10, :EUR)}]
      iex> nodes_weight({nodes, vertices})
      %{
        ?A => Money.new(-10, :EUR),
        ?B => Money.new(10, :EUR)
      }

  """
  @spec nodes_weight(t()) :: %{point() => weight()}
  def nodes_weight({nodes, vertices}) do
    zeroed_weights = Map.new(nodes, &{&1, zero_money()})

    Enum.reduce(vertices, zeroed_weights, fn %{from: from, to: to, weight: weight}, weights ->
      weights
      |> Map.update!(from, &Money.subtract(&1, weight))
      |> Map.update!(to, &Money.add(&1, weight))
    end)
  end

  @doc """
  Create a graph from a list of `peer_balance`.
  """
  @spec from_peer_balances([Balance.peer_balance()]) :: t()
  def from_peer_balances(balances) do
    Enum.reduce(
      balances,
      {MapSet.new(), []},
      fn %{from: from, to: to, amount: amount}, {points, vertices} ->
        new_points =
          points
          |> MapSet.put(from)
          |> MapSet.put(to)

        new_vertices = [%{from: from, to: to, weight: amount} | vertices]

        {new_points, new_vertices}
      end
    )
  end

  @zero_money Money.new(0, :EUR)
  defp zero_money, do: @zero_money
end
