defmodule App.Balance.TransferParams do
  @moduledoc """
  A type representing a means - and their associated parameters - of balance transfers.
  """

  ## Type definition

  use Ecto.Type

  alias App.Balance.Means

  @enforce_keys [:means_code, :params]
  defstruct means_code: nil, params: nil

  @type t :: %{
          means_code: Means.code(),
          params: map()
        }

  def type, do: :balance_transfer_params

  @codes Means.codes()
  @string_codes Enum.map(@codes, &Atom.to_string/1)

  # Provide custom casting rules
  def cast(%__MODULE__{} = input) do
    {:ok, input}
  end

  def cast(%{means_code: means_code} = input) when means_code in @codes do
    cast_normalized(means_code, input[:params])
  end

  def cast(%{"means_code" => means_code} = input) when means_code in @string_codes do
    cast_normalized(String.to_existing_atom(means_code), input["params"])
  end

  def cast(_), do: :error

  defp cast_normalized(means_code, params) do
    if message = params_mismatch(means_code, params) do
      {:error, message: message}
    else
      {:ok, %__MODULE__{means_code: means_code, params: params}}
    end
  end

  # Validate that the params matches the pattern required by the code.
  # Returns `nil` if no error is found, or a string describing the error otherwise.
  defp params_mismatch(:divide_equally, params) do
    unless is_nil(params), do: "did not expect any parameter"
  end

  defp params_mismatch(:weight_by_income, params) do
    unless is_nil(params), do: "did not expect any parameter"
  end

  defp params_mismatch(_code, _params), do: "is invalid"

  # Load data from the database
  def load({means_code, params}) do
    {:ok, %__MODULE__{means_code: String.to_existing_atom(means_code), params: params}}
  end

  def load(_), do: :error

  # Dumps term to the database
  def dump(%{means_code: means_code, params: params}) do
    {:ok, {Atom.to_string(means_code), params}}
  end

  def dump(_), do: :error
end
