defmodule App.Balance.BalanceConfigsTest do
  use App.DataCase, async: true

  import App.AccountsFixtures
  import App.Balance.BalanceConfigsFixtures
  import App.Books.MembersFixtures
  import App.BooksFixtures
  import App.TransfersFixtures

  alias App.Balance.BalanceConfig
  alias App.Balance.BalanceConfigs

  describe "get_balance_config_of_member/1" do
    test "returns the balance config of the member" do
      %{id: id} = balance_config_fixture()
      member = book_member_fixture(book_fixture(), balance_config_id: id)

      assert %{id: ^id} = BalanceConfigs.get_balance_config_of_member(member)
    end

    test "returns nil if the member has no balance configuration" do
      member = book_member_fixture(book_fixture())

      assert BalanceConfigs.get_balance_config_of_member(member) == nil
    end
  end

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

  describe "create_balance_config/3" do
    test "creates a balance configuration" do
      former_balance_config = balance_config_fixture()

      member = book_member_fixture(book_fixture(), balance_config_id: former_balance_config.id)
      owner = user_fixture()

      assert {:ok, balance_config} =
               BalanceConfigs.create_balance_config(member, owner, %{annual_income: 5432})

      assert balance_config.owner_id == owner.id
      assert balance_config.annual_income == 5432

      # updates the member
      member = Repo.reload!(member)
      assert member.balance_config_id == balance_config.id

      # does not delete the former balance configuration
      assert Repo.reload(former_balance_config)
    end

    test "returns an error if the attributes are invalid" do
      member = book_member_fixture(book_fixture())
      owner = user_fixture()

      assert {:error, changeset} =
               BalanceConfigs.create_balance_config(member, owner, %{annual_income: -1})

      assert errors_on(changeset) == %{annual_income: ["must be greater than or equal to 0"]}
    end
  end

  describe "change_balance_config_revenues/2" do
    setup do
      %{balance_config: balance_config_fixture()}
    end

    test "returns a changeset", %{balance_config: balance_config} do
      assert %Ecto.Changeset{} =
               changeset =
               BalanceConfigs.change_balance_config_revenues(balance_config, %{
                 annual_income: 2345
               })

      assert changeset.valid?
      assert changeset.changes == %{annual_income: 2345}
    end

    test "cannot change the owner", %{balance_config: balance_config} do
      assert %Ecto.Changeset{} =
               changeset =
               BalanceConfigs.change_balance_config_revenues(balance_config, %{
                 owner_id: user_fixture().id
               })

      assert changeset.valid?
      assert changeset.changes == %{}
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
