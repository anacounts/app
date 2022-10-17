defmodule App.Balance.ConfigTest do
  use App.DataCase, async: true

  import App.Balance.ConfigFixtures
  import App.AuthFixtures

  alias App.Balance.Config

  describe "get_user_config_or_default/2" do
    setup do
      %{user: user_fixture()}
    end

    test "returns the balance config of the user", %{user: user} do
      user_balance_config_fixture(user, annual_income: 1234)

      assert %{annual_income: 1234} = Config.get_user_config_or_default(user)
    end

    test "retuns a default value if the user does not have a balance config yet", %{user: user} do
      assert user_config = Config.get_user_config_or_default(user)

      assert user_config.user == user
      assert user_config.user_id == user.id
      assert user_config.annual_income == nil
    end
  end

  describe "update_user_config/1" do
    setup do
      %{user: user_fixture()}
    end

    test "creates the user config if it does not exist", %{user: user} do
      user_config = Config.get_user_config_or_default(user)
      assert Ecto.get_meta(user_config, :state) == :built

      assert {:ok, user_config} = Config.update_user_config(user_config, %{})
      assert Ecto.get_meta(user_config, :state) == :loaded
    end

    test "updates the user config", %{user: user} do
      user_config = user_balance_config_fixture(user, annual_income: 1234)

      assert {:ok, user_config} = Config.update_user_config(user_config, %{annual_income: 2345})
      assert user_config.annual_income == 2345
    end

    test "fails if a value is incorrect", %{user: user} do
      user_config = user_balance_config_fixture(user)

      assert {:error, changeset} = Config.update_user_config(user_config, %{annual_income: -1})
      assert errors_on(changeset) == %{annual_income: ["must be greater than or equal to 0"]}
    end
  end
end
