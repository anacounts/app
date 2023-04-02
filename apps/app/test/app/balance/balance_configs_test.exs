defmodule App.Balance.BalanceConfigsTest do
  use App.DataCase, async: true

  import App.AccountsFixtures
  import App.Balance.BalanceConfigsFixtures

  alias App.Balance.BalanceConfigs

  @valid_annual_income 1234
  @updated_annual_income 2345

  describe "get_user_balance_config_or_default/1" do
    setup do
      %{user: user_fixture()}
    end

    test "returns the balance config of the user", %{user: user} do
      user_balance_config_fixture(user, annual_income: @valid_annual_income)

      user = Repo.reload(user)

      assert %{annual_income: @valid_annual_income} =
               BalanceConfigs.get_user_balance_config_or_default(user)
    end
  end

  describe "update_balance_config/1" do
    setup do
      %{user: user_fixture()}
    end

    test "updates the user config", %{user: user} do
      balance_config = user_balance_config_fixture(user, annual_income: @valid_annual_income)

      assert {:ok, balance_config} =
               BalanceConfigs.update_balance_config(balance_config, %{
                 annual_income: @updated_annual_income
               })

      assert balance_config.annual_income == @updated_annual_income
    end

    test "fails if a value is incorrect", %{user: user} do
      balance_config = user_balance_config_fixture(user)

      assert {:error, changeset} =
               BalanceConfigs.update_balance_config(balance_config, %{annual_income: -1})

      assert errors_on(changeset) == %{annual_income: ["must be greater than or equal to 0"]}
    end
  end
end
