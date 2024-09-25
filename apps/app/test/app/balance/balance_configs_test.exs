defmodule App.Balance.BalanceConfigsTest do
  use App.DataCase, async: true

  import App.AccountsFixtures
  import App.Balance.BalanceConfigsFixtures
  import App.Books.MembersFixtures
  import App.BooksFixtures
  import App.TransfersFixtures

  alias App.Balance.BalanceConfig
  alias App.Balance.BalanceConfigs

  describe "member_has_revenues?/1" do
    setup do
      %{book: book_fixture()}
    end

    test "returns false if the member has no balance configuration", %{book: book} do
      member = book_member_fixture(book)
      assert not BalanceConfigs.member_has_revenues?(member)
    end

    test "returns false if the balance configuration has no annual income set", %{book: book} do
      balance_config = balance_config_fixture(annual_income: nil)
      member = book_member_fixture(book, balance_config_id: balance_config.id)

      assert not BalanceConfigs.member_has_revenues?(member)
    end

    test "returns true if the balance configuration has an annual income set", %{book: book} do
      balance_config = balance_config_fixture(annual_income: 2345)
      member = book_member_fixture(book, balance_config_id: balance_config.id)

      assert BalanceConfigs.member_has_revenues?(member)
    end
  end

  describe "try_to_delete_balance_config/1" do
    setup do
      %{balance_config: balance_config_fixture()}
    end

    test "deletes the balance configuration if it's not linked to any entity", %{
      balance_config: balance_config
    } do
      :ok = BalanceConfigs.try_to_delete_balance_config(balance_config)

      refute Repo.reload(balance_config)
    end

    test "does not delete the balance configuration if it's linked to a member", %{
      balance_config: balance_config
    } do
      book = book_fixture()
      _member = book_member_fixture(book, balance_config_id: balance_config.id)

      :ok = BalanceConfigs.try_to_delete_balance_config(balance_config)

      assert Repo.reload(balance_config)
    end

    test "does not delete the balance configuration if it's linked to a peer", %{
      balance_config: balance_config
    } do
      book = book_fixture()
      member = book_member_fixture(book)
      transfer = money_transfer_fixture(book, tenant_id: member.id)
      _peer = peer_fixture(transfer, member_id: member.id, balance_config_id: balance_config.id)

      :ok = BalanceConfigs.try_to_delete_balance_config(balance_config)

      assert Repo.reload(balance_config)
    end

    test "does not end the transaction on error", %{balance_config: balance_config} do
      user = user_fixture()

      {:ok, balance_config} =
        Repo.transaction(fn ->
          book = book_fixture()
          _member = book_member_fixture(book, balance_config_id: balance_config.id)

          :ok = BalanceConfigs.try_to_delete_balance_config(balance_config)

          # Try to insert another entity in the database
          Repo.insert!(%BalanceConfig{owner_id: user.id})
        end)

      assert balance_config.owner_id == user.id
    end
  end
end
