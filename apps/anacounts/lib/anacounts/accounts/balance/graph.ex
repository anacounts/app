defmodule Anacounts.Accounts.Balance.Graph do
  @moduledoc """
  A weighted graph representation of the peer balances.

  Expose methods to manipulate the graph, including optimizing
  the graph to a minimal graph.
  """

  alias Anacounts.Accounts
  alias Anacounts.Accounts.Balance

  @type t :: {MapSet.t(point()), [vertex()]}

  # a node in the graph
  @typep point :: Accounts.BookMember.id()

  # a link between two points in the graph
  @typep vertex :: %{from: point(), to: point(), weight: weight()}

  # the weight of a vertex
  @typep weight :: Money.t()

  @doc """
  Get the graph vertices.

  ## Example

      iex> vertices({[?A, ?B, ?C], []})
      []
      iex> vertices({[?A, ?B], [
      ...>   %{from: ?A, to: ?B, weight: Money.new(100, :EUR)},
      ...>   %{from: ?A, to: ?A, weight: Money.new(50, :EUR)}
      ...> ]})
      [
        %{from: ?A, to: ?B, weight: Money.new(100, :EUR)},
        %{from: ?A, to: ?A, weight: Money.new(50, :EUR)}
      ]
  """
  @spec vertices(t()) :: [vertex()]
  def vertices({_node, vertices}), do: vertices

  @doc """
  For each node, add the outgoing vertexes and substract the incoming vertexes weights.
  This gives a summary of each nodes incoming and outgoing weight.

  ## Example

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

  @doc """
  Optimize the number of vertices in a graph.
  Makes the weighted vertices go directly to their final destination.

  ## Example

  With a graph composed of 3 nodes A, B, C and 3 vertices A -1> B, B -2> C, C -3> A;
  the vertices are reduced to B -1> A, C -1> A.

      iex> nodes = nil # nodes are ignored in this algorithm anyway
      iex> vertices = [
      ...>   %{from: ?A, to: ?B, weight: Money.new(1, :EUR)},
      ...>   %{from: ?B, to: ?C, weight: Money.new(2, :EUR)},
      ...>   %{from: ?C, to: ?A, weight: Money.new(3, :EUR)},
      ...> ]
      iex> contract_vertices({nodes, vertices})
      {nil, [
        %{from: ?B, to: ?A, weight: Money.new(1, :EUR)},
        %{from: ?C, to: ?A, weight: Money.new(1, :EUR)}]
      }
  """
  @spec contract_vertices(t()) :: t()
  def contract_vertices({nodes, vertices}) do
    reduced_vertices = reduce_vertices(vertices)

    {nodes, reduced_vertices}
    |> combine_redundant_vertices()
    |> reject_weigthless_vertices()
  end

  # algorithm:
  # - take first vertex v1
  # - take first vertex v2 where v1.to == v2.from
  # - if v2 is nil, take next vertex v1
  # - remove min(v1.weight, v2.weight) from v1 and v2 weight
  # - create v3 = %{v1.from, v2.to, v2.weight - v1.weight}
  # - repeat
  defp reduce_vertices(vertices)

  defp reduce_vertices(vertices) do
    case find_matching_vertices(vertices) do
      {v1, v2, other_vertices} ->
        created_vertices = [
          # new vertex
          %{from: v1.from, to: v2.to, weight: min(v1.weight, v2.weight)},
          # updated vertex
          if(Money.cmp(v1.weight, v2.weight) == :gt,
            do: %{v1 | weight: Money.subtract(v1.weight, v2.weight)},
            else: %{v2 | weight: Money.subtract(v2.weight, v1.weight)}
          )
        ]

        added_vertices =
          Enum.reject(created_vertices, &(&1.from == &1.to or Money.zero?(&1.weight)))

        reduce_vertices(added_vertices ++ other_vertices)

      nil ->
        vertices
    end
  end

  # TODO refactor in a more... Elixir way
  defp find_matching_vertices(vertices) do
    matching_entry =
      Enum.find_value(vertices, fn v1 ->
        v2 = Enum.find(vertices, fn v2 -> v1.to == v2.from end)
        if v2, do: {v1, v2}
      end)

    if matching_entry do
      {v1, v2} = matching_entry

      updated_vertices =
        vertices
        |> List.delete(v1)
        |> List.delete(v2)

      {v1, v2, updated_vertices}
    end
  end

  defp combine_redundant_vertices({nodes, vertices}) do
    combined_vertices =
      vertices
      |> Enum.group_by(&{&1.from, &1.to}, & &1.weight)
      |> Enum.map(fn {{from, to}, weights} ->
        %{from: from, to: to, weight: sum_weights(weights)}
      end)

    {nodes, combined_vertices}
  end

  defp reject_weigthless_vertices({nodes, vertices}) do
    new_vertices = Enum.reject(vertices, &Money.zero?(&1.weight))
    {nodes, new_vertices}
  end

  defp sum_weights([]), do: zero_money()
  defp sum_weights([money | rest]), do: Money.add(money, sum_weights(rest))

  defp zero_money, do: Money.new(0, :EUR)
end
