defmodule AnacountsAPI.Schema.CustomTypes do
  @moduledoc """
  Define custom types for Absinthe.
  """

  use Absinthe.Schema.Notation

  alias Absinthe.Blueprint.Input

  ## Money

  scalar :money, name: "Money" do
    serialize(&serialize_money/1)
    parse(&parse_money/1)
  end

  @spec serialize_money(Money.t()) :: String.t()
  def serialize_money(%{amount: amount, currency: currency} = _money) do
    "#{amount}/#{currency}"
  end

  @spec parse_money(Input.String.t()) :: {:ok, Money.t()} | :error
  @spec parse_money(Input.Null.t()) :: {:ok, nil}
  defp parse_money(%Input.String{value: value}) do
    case String.split(value, "/") do
      [raw_amount, currency] -> Money.parse(raw_amount, currency)
      _ -> :error
    end
  end

  defp parse_money(%Input.Null{}) do
    {:ok, nil}
  end

  defp parse_money(_) do
    :error
  end

  ## JSON

  scalar :json, name: "Json" do
    description("""
    The `Json` scalar type represents arbitrary json string data, represented as UTF-8
    character sequences. The Json type is most often used to represent a free-form
    human-readable json string.
    """)

    serialize(&serialize_json/1)
    parse(&parse_json/1)
  end

  defp serialize_json(value), do: value

  @spec parse_json(Absinthe.Blueprint.Input.String.t()) :: {:ok, :string} | :error
  @spec parse_json(Absinthe.Blueprint.Input.Null.t()) :: {:ok, nil}
  defp parse_json(%Absinthe.Blueprint.Input.String{value: value}) do
    case Jason.decode(value) do
      {:ok, result} -> {:ok, result}
      _ -> :error
    end
  end

  defp parse_json(%Absinthe.Blueprint.Input.Null{}) do
    {:ok, nil}
  end

  defp parse_json(_) do
    :error
  end
end
