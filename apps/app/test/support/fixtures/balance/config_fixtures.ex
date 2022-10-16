defmodule App.Balance.ConfigFixtures do
  @moduledoc """
  Fixtures for the `App.Balance.Config` context
  """

  alias App.Balance.Config

  def user_balance_config_fixture(user, attrs \\ %{}) do
    clean_attrs = Enum.into(attrs, %{})

    {:ok, user_config} =
      Config.get_user_config_or_default(user)
      |> Config.update_user_config(clean_attrs)

    user_config
  end

  def setup_user_balance_config_fixture(%{user: user} = context) do
    Map.put(context, :user_balance_config, user_balance_config_fixture(user))
  end
end
