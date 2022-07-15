defmodule Anacounts.Accounts.Balance.TransferParams do
  use Ecto.Type
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
end
