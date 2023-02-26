defmodule App.Balance.BalanceConfigsTest do
  use App.DataCase, async: true

  import App.Balance.BalanceConfigsFixtures
  import App.AuthFixtures

  alias App.Balance.BalanceConfigs

  describe "get_user_config_or_default/2" do
    setup do
      %{user: user_fixture()}
    end

    test "returns the balance config of the user", %{user: user} do
      user_balance_config_fixture(user, annual_income: 1234)

      assert %{annual_income: 1234} = BalanceConfigs.get_user_config_or_default(user)
    end
  end

  describe "update_balance_config/1" do
    setup do
      %{user: user_fixture()}
    end

    test "updates the user config", %{user: user} do
      balance_config = user_balance_config_fixture(user, annual_income: 1234)

      assert {:ok, balance_config} =
               BalanceConfigs.update_balance_config(balance_config, %{annual_income: 2345})

      assert balance_config.annual_income == 2345
    end

    test "fails if a value is incorrect", %{user: user} do
      balance_config = user_balance_config_fixture(user)

      assert {:error, changeset} =
               BalanceConfigs.update_balance_config(balance_config, %{annual_income: -1})

      assert errors_on(changeset) == %{annual_income: ["must be greater than or equal to 0"]}
    end
  end
end
