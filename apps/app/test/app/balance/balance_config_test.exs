defmodule App.Balance.BalanceConfigTest do
  use App.DataCase, async: true

  import App.AccountsFixtures
  import App.Balance.BalanceConfigsFixtures

  alias App.Balance.BalanceConfig

  setup do
    %{user: user_fixture()}
  end

  describe "changeset/2" do
    test "allows past and present `:start_date_of_validity`", %{user: user} do
      changeset =
        BalanceConfig.changeset(
          %BalanceConfig{},
          balance_config_attributes(user,
            start_date_of_validity: DateTime.utc_now() |> DateTime.add(-1, :day)
          )
        )

      assert changeset.valid?

      changeset =
        BalanceConfig.changeset(
          %BalanceConfig{},
          balance_config_attributes(user,
            start_date_of_validity: DateTime.utc_now()
          )
        )

      assert changeset.valid?
    end

    test "does not allow future `:start_date_of_validity`", %{user: user} do
      changeset =
        BalanceConfig.changeset(
          %BalanceConfig{},
          balance_config_attributes(user,
            start_date_of_validity: DateTime.utc_now() |> DateTime.add(1, :day)
          )
        )

      refute changeset.valid?
      assert errors_on(changeset) == %{start_date_of_validity: ["must be now or a past date"]}
    end

    test "does allow valid `:annual_income`", %{user: user} do
      changeset =
        BalanceConfig.changeset(
          %BalanceConfig{},
          balance_config_attributes(user,
            annual_income: 0
          )
        )

      assert changeset.valid?
    end

    test "does not allow negative `:annual_income`", %{user: user} do
      changeset =
        BalanceConfig.changeset(
          %BalanceConfig{},
          balance_config_attributes(user,
            annual_income: -1
          )
        )

      refute changeset.valid?
      assert errors_on(changeset) == %{annual_income: ["must be greater than or equal to 0"]}
    end
  end
end
