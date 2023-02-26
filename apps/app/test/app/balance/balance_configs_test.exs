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

    test "retuns a default value if the user does not have a balance config yet", %{user: user} do
      assert balance_config = BalanceConfigs.get_user_config_or_default(user)

      assert balance_config.user == user
      assert balance_config.user_id == user.id
      assert balance_config.annual_income == nil
    end
  end

  describe "update_balance_config/1" do
    setup do
      %{user: user_fixture()}
    end

    test "creates the user config if it does not exist", %{user: user} do
      balance_config = BalanceConfigs.get_user_config_or_default(user)
      assert Ecto.get_meta(balance_config, :state) == :built

      assert {:ok, balance_config} = BalanceConfigs.update_balance_config(balance_config, %{})
      assert Ecto.get_meta(balance_config, :state) == :loaded
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
