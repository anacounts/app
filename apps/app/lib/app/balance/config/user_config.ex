defmodule App.Balance.Config.UserConfig do
  @moduledoc """
  The users configuration related to balancing.

  This includes private data, which is encrypted in the database.
  """
  use Ecto.Schema
  import Ecto.Changeset

  alias App.Auth.User

  @type id :: integer()

  @type t :: %__MODULE__{
          id: id(),
          annual_income: non_neg_integer(),
          user: User.t() | Ecto.Association.NotLoaded.t(),
          user_id: User.id()
        }

  @derive {Inspect, only: [:id, :user, :user_id]}
  schema "balance_configs" do
    field :annual_income, App.Encrypted.Integer

    belongs_to :user, User
  end

  def changeset(struct, attrs) do
    struct
    |> cast(attrs, [:annual_income])
    |> validate_annual_income()
    |> validate_user_id()
  end

  defp validate_annual_income(changeset) do
    changeset
    |> validate_number(:annual_income, greater_than_or_equal_to: 0)
  end

  defp validate_user_id(changeset) do
    changeset
    |> validate_required(:user_id)
    |> foreign_key_constraint(:user_id)
  end
end
