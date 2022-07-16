defmodule Anacounts.Accounts.Balance.TransferParams do
  @moduledoc """
  A type representing a means - and their associated parameters - of balance transfers.
  """

  ## Type definition

  use Ecto.Type

  import Ecto.Changeset

  alias Anacounts.Accounts.Balance.Means

  @type t :: %{
          means_code: Means.code(),
          params: map()
        }

  def type, do: :balance_transfer_params

  # TODO refactor
  # An awesome way to do this would be to create a basic "Tuple" type,
  # with a module/struct as parameter. It could then get its fields on load and fill them,
  # dump them the same way, etc...
  # See if it's feasible
  # Another absolutely awesome thing, would be to add it to Ecto itself \o/

  # Provide custom casting rules
  def cast(%{means_code: means_code, params: params} = input)
      when is_atom(means_code) and is_map(params) do
    {:ok, input}
  end

  def cast(%{"means_code" => means_code, "params" => params})
      when is_atom(means_code) and is_map(params) do
    {:ok, %{means_code: means_code, params: params}}
  end

  def cast(_), do: :error

  # Load data from the database
  @spec load({binary, any}) :: {:ok, %{means_code: atom, params: any}}
  def load({means_code, params}) do
    {:ok, %{means_code: String.to_existing_atom(means_code), params: params}}
  end

  # Dumps term to the database
  def dump(%{means_code: means_code, params: params}) do
    {:ok, {Atom.to_string(means_code), params}}
  end

  def dump(_), do: :error

  ## Changeset

  @spec validate_changeset(Ecto.Changeset.t(), atom()) :: Ecto.Changeset.t()
  def validate_changeset(changeset, field) do
    transfer_params = get_field(changeset, field)

    if transfer_params do
      changeset
      |> validate_means_code(field, transfer_params)
      |> validate_params(field, transfer_params)
      |> validate_matching_code_and_params(field, transfer_params)
    else
      changeset
    end
  end

  defp validate_means_code(changeset, field, %{means_code: means_code}) do
    if means_code in Means.codes() do
      changeset
    else
      add_error(changeset, field, "is invalid")
    end
  end

  defp validate_params(changeset, field, transfer_params) do
    if Map.get(transfer_params, :params) do
      changeset
    else
      add_error(changeset, field, "can't be blank")
    end
  end

  defp validate_matching_code_and_params(%{valid?: false} = changeset, _field, _transfer_params),
    do: changeset

  defp validate_matching_code_and_params(changeset, field, %{
         means_code: means_code,
         params: params
       }) do
    if error = params_mismatch(means_code, params) do
      add_error(changeset, field, error)
    else
      changeset
    end
  end

  # Validate that the params match the one required by the code
  defp params_mismatch(:divide_equally, params) do
    unless Enum.empty?(params), do: "did not expect any parameter"
  end

  defp params_mismatch(:weight_by_income, params) do
    unless Enum.empty?(params), do: "did not expect any parameter"
  end

  defp params_mismatch(_code, _params), do: "is invalid"
end
