defmodule AnacountsAPI.Schema.CustomTypes do
  use Absinthe.Schema.Notation

  alias Absinthe.Blueprint.Input

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
    with [raw_amount, currency] <- String.split(value, "/") do
      Money.parse(raw_amount, currency)
    else
      _ -> :error
    end
  end

  defp parse_money(%Input.Null{}) do
    {:ok, nil}
  end

  defp parse_money(_) do
    :error
  end
end
