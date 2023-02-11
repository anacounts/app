defmodule App.Balance.Config.UserConfig do
  @moduledoc """
  The users configuration related to balancing.

  This includes private data, which is encrypted in the database.
  """
  use Ecto.Schema
  import Ecto.Changeset

  @type id :: integer()

  @type t :: %__MODULE__{
          id: id(),
          annual_income: non_neg_integer()
        }

  @derive {Inspect, only: [:id]}
  schema "balance_configs" do
    field :annual_income, App.Encrypted.Integer
  end

  def changeset(struct, attrs) do
    struct
    |> cast(attrs, [:annual_income])
    |> validate_annual_income()
  end

  defp validate_annual_income(changeset) do
    changeset
    |> validate_number(:annual_income, greater_than_or_equal_to: 0)
  end
end
