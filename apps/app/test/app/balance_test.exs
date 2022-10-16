defmodule App.BalanceTest do
  use App.DataCase, async: true

  import App.BalanceFixtures
  import App.AuthFixtures
  import App.BooksFixtures
  import App.Books.MembersFixtures
  import App.TransfersFixtures

  alias App.Balance

  describe "for_book/1" do
    setup :setup_user_fixture
    setup :setup_book_fixture

    test "balances transfers correctly", %{book: %{members: [member]} = book} do
      other_user = user_fixture()
      other_member = book_member_fixture(book, other_user)

      _money_transfer =
        money_transfer_fixture(
          amount: Money.new(10, :EUR),
          book_id: book.id,
          tenant_id: member.id,
          peers: [%{member_id: member.id}, %{member_id: other_member.id}]
        )

      assert Balance.for_book(book.id) == %{
               members_balance: %{
                 member.id => Money.new(5, :EUR),
                 other_member.id => Money.new(-5, :EUR)
               },
               transactions: [
                 %{
                   amount: Money.new(5, :EUR),
                   from: other_member.id,
                   to: member.id
                 }
               ]
             }
    end

    test "balances multiple transfers correctly #1", %{book: %{members: [member1]} = book} do
      member2 = book_member_fixture(book, user_fixture())
      member3 = book_member_fixture(book, user_fixture())
      member4 = book_member_fixture(book, user_fixture())

      _transfer1 =
        money_transfer_fixture(
          amount: Money.new(400, :EUR),
          book_id: book.id,
          tenant_id: member1.id,
          peers: [
            %{member_id: member1.id},
            %{member_id: member2.id},
            %{member_id: member3.id},
            %{member_id: member4.id}
          ]
        )

      _transfer2 =
        money_transfer_fixture(
          amount: Money.new(400, :EUR),
          book_id: book.id,
          tenant_id: member2.id,
          peers: [
            %{member_id: member1.id},
            %{member_id: member2.id},
            %{member_id: member3.id},
            %{member_id: member4.id}
          ]
        )

      assert Balance.for_book(book.id) == %{
               members_balance: %{
                 member1.id => Money.new(200, :EUR),
                 member2.id => Money.new(200, :EUR),
                 member3.id => Money.new(-200, :EUR),
                 member4.id => Money.new(-200, :EUR)
               },
               transactions: [
                 %{from: member4.id, to: member2.id, amount: Money.new(200, :EUR)},
                 %{from: member3.id, to: member1.id, amount: Money.new(200, :EUR)}
               ]
             }
    end

    test "balances multiple transfers correctly #2", %{book: %{members: [member1]} = book} do
      member2 = book_member_fixture(book, user_fixture())
      member3 = book_member_fixture(book, user_fixture())

      _transfer1 =
        money_transfer_fixture(
          amount: Money.new(300, :EUR),
          book_id: book.id,
          tenant_id: member1.id,
          peers: [
            %{member_id: member1.id},
            %{member_id: member2.id},
            %{member_id: member3.id}
          ]
        )

      _transfer2 =
        money_transfer_fixture(
          amount: Money.new(300, :EUR),
          book_id: book.id,
          tenant_id: member2.id,
          peers: [
            %{member_id: member1.id},
            %{member_id: member2.id},
            %{member_id: member3.id}
          ]
        )

      assert Balance.for_book(book.id) == %{
               members_balance: %{
                 member1.id => Money.new(100, :EUR),
                 member2.id => Money.new(100, :EUR),
                 member3.id => Money.new(-200, :EUR)
               },
               transactions: [
                 %{from: member3.id, to: member2.id, amount: Money.new(100, :EUR)},
                 %{from: member3.id, to: member1.id, amount: Money.new(100, :EUR)}
               ]
             }
    end

    test "does not crash if the book is correctly balanced", %{book: %{members: [member1]} = book} do
      member2 = book_member_fixture(book, user_fixture())
      member3 = book_member_fixture(book, user_fixture())

      _transfer1 =
        money_transfer_fixture(
          amount: Money.new(300, :EUR),
          book_id: book.id,
          tenant_id: member1.id,
          peers: [
            %{member_id: member1.id},
            %{member_id: member2.id},
            %{member_id: member3.id}
          ]
        )

      _reimbursement1 =
        money_transfer_fixture(
          amount: Money.new(100, :EUR),
          type: :reimbursement,
          book_id: book.id,
          tenant_id: member1.id,
          peers: [%{member_id: member2.id}]
        )

      _reimbursement1 =
        money_transfer_fixture(
          amount: Money.new(100, :EUR),
          type: :reimbursement,
          book_id: book.id,
          tenant_id: member1.id,
          peers: [%{member_id: member3.id}]
        )

      assert Balance.for_book(book.id) == %{
               members_balance: %{
                 member1.id => Money.new(0, :EUR),
                 member2.id => Money.new(0, :EUR),
                 member3.id => Money.new(0, :EUR)
               },
               transactions: []
             }
    end
  end

  describe "get_user_config_or_default/2" do
    setup :setup_user_fixture

    test "returns the balance config of the user", %{user: user} do
      user_balance_config_fixture(user, annual_income: 1234)

      assert %{annual_income: 1234} = Balance.get_user_config_or_default(user)
    end

    test "retuns a default value if the user does not have a balance config yet", %{user: user} do
      assert user_config = Balance.get_user_config_or_default(user)

      assert user_config.user == user
      assert user_config.user_id == user.id
      assert user_config.annual_income == nil
    end
  end

  describe "update_user_config/1" do
    setup :setup_user_fixture

    test "creates the user config if it does not exist", %{user: user} do
      user_config = Balance.get_user_config_or_default(user)
      assert Ecto.get_meta(user_config, :state) == :built

      assert {:ok, user_config} = Balance.update_user_config(user_config, %{})
      assert Ecto.get_meta(user_config, :state) == :loaded
    end

    test "updates the user config", %{user: user} do
      user_config = user_balance_config_fixture(user, annual_income: 1234)

      assert {:ok, user_config} = Balance.update_user_config(user_config, %{annual_income: 2345})
      assert user_config.annual_income == 2345
    end

    test "fails if a value is incorrect", %{user: user} do
      user_config = user_balance_config_fixture(user)

      assert {:error, changeset} = Balance.update_user_config(user_config, %{annual_income: -1})
      assert errors_on(changeset) == %{annual_income: ["must be greater than or equal to 0"]}
    end
  end
end
