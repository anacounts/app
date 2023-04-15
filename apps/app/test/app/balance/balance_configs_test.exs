defmodule App.Balance.BalanceConfigsTest do
  use App.DataCase, async: true

  import App.AccountsFixtures
  import App.Balance.BalanceConfigsFixtures
  import App.Books.MembersFixtures
  import App.BooksFixtures

  alias App.Repo

  alias App.Balance.BalanceConfig
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

  describe "update_user_balance_config/3" do
    setup do
      %{user: user_fixture()}
    end

    test "creates a first balance config for a user", %{user: user} do
      balance_config = %BalanceConfig{owner_id: user.id, created_for: :user}

      assert {:ok, balance_config} =
               BalanceConfigs.update_user_balance_config(user, balance_config, %{
                 annual_income: @valid_annual_income
               })

      assert balance_config.annual_income == @valid_annual_income
    end

    test "create a new balance config for the user", %{user: user} do
      old_balance_config = user_balance_config_fixture(user, annual_income: @valid_annual_income)

      assert {:ok, new_balance_config} =
               BalanceConfigs.update_user_balance_config(user, old_balance_config, %{
                 annual_income: @updated_annual_income
               })

      assert new_balance_config.id != old_balance_config.id
      assert new_balance_config.annual_income == @updated_annual_income
    end

    test "updates members linked to the user", %{user: user} do
      old_balance_config = user_balance_config_fixture(user, annual_income: @valid_annual_income)

      book = book_fixture()
      member1 = book_member_fixture(book, user_id: user.id)
      member2 = book_member_fixture(book)
      member_balance_config_link_fixture(member2, old_balance_config)
      member3 = book_member_fixture(book)

      assert {:ok, new_balance_config} =
               BalanceConfigs.update_user_balance_config(user, old_balance_config, %{
                 annual_income: @updated_annual_income
               })

      assert Repo.reload(member1).balance_config_id == new_balance_config.id
      assert Repo.reload(member2).balance_config_id != new_balance_config.id
      assert Repo.reload(member3).balance_config_id != new_balance_config.id
    end

    test "fails if a value is incorrect", %{user: user} do
      balance_config = user_balance_config_fixture(user)

      assert {:error, changeset} =
               BalanceConfigs.update_user_balance_config(user, balance_config, %{
                 annual_income: -1
               })

      assert errors_on(changeset) == %{annual_income: ["must be greater than or equal to 0"]}
    end
  end
end
