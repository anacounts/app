defmodule App.Accounts.Balance.UserParams do
  @moduledoc """
  A type representing a means - and their associated parameters - of balance transfers.
  """
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query

  alias App.Accounts.Balance.Means
  alias App.Auth

  @type id :: integer()

  @type t :: %__MODULE__{
          id: id(),
          means_code: Means.code(),
          params: map(),
          user: Auth.User.t()
        }

  schema "balance_user_params" do
    field(:means_code, Ecto.Enum, values: Means.codes_with_user_params())
    # TODO crypt this data, must require to change to :binary data type
    field(:params, :map)

    belongs_to(:user, Auth.User)
  end

  ## Changeset

  def changeset(attrs) do
    %__MODULE__{}
    |> cast(attrs, [:means_code, :params, :user_id])
    |> validate_means_code()
    |> validate_params()
    |> validate_matching_code_and_params()
    |> validate_user_id()
  end

  defp validate_means_code(changeset) do
    changeset
    |> validate_required(:means_code)
    |> validate_inclusion(:means_code, Means.codes_with_user_params())
  end

  defp validate_params(changeset) do
    changeset
    |> validate_required(:params)
  end

  # always call after `validate_means_code` and `validate_params`,
  # ensuring the values passed are valid
  defp validate_matching_code_and_params(changeset)
  defp validate_matching_code_and_params(%{valid?: false} = changeset), do: changeset

  defp validate_matching_code_and_params(changeset) do
    means_code = fetch_field!(changeset, :means_code)
    params = fetch_field!(changeset, :params)

    if error = params_mismatch(means_code, params) do
      add_error(changeset, :params, error)
    else
      changeset
    end
  end

  defp params_mismatch(:divide_equally, params) do
    unless Enum.empty?(params), do: "did not expect any parameter"
  end

  defp params_mismatch(:weight_by_income, params) do
    cond do
      non_neg_integer?(params["income"]) -> nil
      non_neg_integer?(params[:income]) -> nil
      true -> "income must be a non-negative integer"
    end
  end

  defp params_mismatch(_code, _params), do: "is invalid"

  defp non_neg_integer?(nil), do: false
  defp non_neg_integer?(value) when is_integer(value) and value >= 0, do: true

  defp non_neg_integer?(value) when is_binary(value) do
    case Integer.parse(value) do
      {integer, ""} -> integer > 0
      :error -> false
    end
  end

  defp validate_user_id(changeset) do
    changeset
    |> validate_required(:user_id)
    |> foreign_key_constraint(:user_id)
  end

  ## Query

  def base_query do
    from(__MODULE__, as: :balance_user_params)
  end

  def where_user_id(query, user_id) do
    from([balance_user_params: user_params] in query,
      where: user_params.user_id == ^user_id
    )
  end

  def where_means_code(query, means_code) do
    from([balance_user_params: user_params] in query,
      where: user_params.means_code == ^means_code
    )
  end
end
