defmodule App.Balance.BalanceConfigTest do
  use App.DataCase, async: true

  import App.AccountsFixtures
  import App.Balance.BalanceConfigsFixtures

  alias App.Balance.BalanceConfig

  setup do
    %{user: user_fixture()}
  end

  describe "changeset/2" do
    test "allows valid `:annual_income`", %{user: user} do
      changeset =
        BalanceConfig.changeset(
          %BalanceConfig{},
          balance_config_attributes(
            owner_id: user.id,
            annual_income: 0
          )
        )

      assert changeset.valid?
    end

    test "does not allow negative `:annual_income`", %{user: user} do
      changeset =
        BalanceConfig.changeset(
          %BalanceConfig{},
          balance_config_attributes(
            owner_id: user.id,
            annual_income: -1
          )
        )

      refute changeset.valid?
      assert errors_on(changeset) == %{annual_income: ["must be greater than or equal to 0"]}
    end
  end
end
