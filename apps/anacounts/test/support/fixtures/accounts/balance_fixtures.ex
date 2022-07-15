defmodule Anacounts.Accounts.BalanceFixtures do
  @moduledoc """
  Fixtures for the `Accounts.Balance` context
  """

  alias Anacounts.Accounts.Balance

  def valid_balance_means_code, do: :divide_equally
  def valid_balance_params, do: %{}

  def valid_balance_transfer_params_attrs(attrs \\ %{}) do
    Enum.into(attrs, %{
      means_code: valid_balance_means_code(),
      params: valid_balance_params()
    })
  end

  def valid_balance_user_params_attrs(attrs \\ %{}) do
    Enum.into(attrs, %{
      means_code: valid_balance_means_code(),
      params: valid_balance_params()
    })
  end

  @base_user_params_fixtures [
    %{means_code: :divide_equally, params: %{}}
  ]

  def balance_user_params_fixtures(user) do
    for base_params <- @base_user_params_fixtures do
      {:ok, user_params} =
        base_params
        |> Map.put(:user_id, user.id)
        |> Balance.upsert_user_params()

      user_params
    end
  end

  def setup_balance_user_params_fixtures(%{user: user} = context) do
    Map.put(context, :balance_user_params, balance_user_params_fixtures(user))
  end
end
