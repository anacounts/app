defmodule App.BalanceTest do
  use App.DataCase, async: true

  import App.AccountsFixtures
  import App.Balance.BalanceConfigsFixtures
  import App.Books.MembersFixtures
  import App.BooksFixtures
  import App.TransfersFixtures

  alias App.Balance

  describe "fill_members_balance/1" do
    setup do
      %{book: book_fixture()}
    end

    test "balances transfers correctly", %{book: book} do
      member1 = book_member_fixture(book, user_id: user_fixture().id)
      member2 = book_member_fixture(book, user_id: user_fixture().id)

      _money_transfer =
        money_transfer_fixture(book,
          amount: Money.new(10, :EUR),
          tenant_id: member1.id,
          peers: [%{member_id: member1.id}, %{member_id: member2.id}]
        )

      assert Balance.fill_members_balance([member1, member2]) == [
               %{member1 | balance: Money.new(5, :EUR)},
               %{member2 | balance: Money.new(-5, :EUR)}
             ]
    end

    test "balances multiple transfers correctly #1", %{book: book} do
      member1 = book_member_fixture(book, user_id: user_fixture().id)
      member2 = book_member_fixture(book, user_id: user_fixture().id)
      member3 = book_member_fixture(book, user_id: user_fixture().id)
      member4 = book_member_fixture(book, user_id: user_fixture().id)

      _transfer1 =
        money_transfer_fixture(book,
          amount: Money.new(400, :EUR),
          tenant_id: member1.id,
          peers: [
            %{member_id: member1.id},
            %{member_id: member2.id},
            %{member_id: member3.id},
            %{member_id: member4.id}
          ]
        )

      _transfer2 =
        money_transfer_fixture(book,
          amount: Money.new(400, :EUR),
          tenant_id: member2.id,
          peers: [
            %{member_id: member1.id},
            %{member_id: member2.id},
            %{member_id: member3.id},
            %{member_id: member4.id}
          ]
        )

      assert Balance.fill_members_balance([member1, member2, member3, member4]) ==
               [
                 %{member1 | balance: Money.new(200, :EUR)},
                 %{member2 | balance: Money.new(200, :EUR)},
                 %{member3 | balance: Money.new(-200, :EUR)},
                 %{member4 | balance: Money.new(-200, :EUR)}
               ]
    end

    test "balances multiple transfers correctly #2", %{book: book} do
      member1 = book_member_fixture(book, user_id: user_fixture().id)
      member2 = book_member_fixture(book, user_id: user_fixture().id)
      member3 = book_member_fixture(book, user_id: user_fixture().id)

      _transfer1 =
        money_transfer_fixture(book,
          amount: Money.new(300, :EUR),
          tenant_id: member1.id,
          peers: [
            %{member_id: member1.id},
            %{member_id: member2.id},
            %{member_id: member3.id}
          ]
        )

      _transfer2 =
        money_transfer_fixture(book,
          amount: Money.new(300, :EUR),
          tenant_id: member2.id,
          peers: [
            %{member_id: member1.id},
            %{member_id: member2.id},
            %{member_id: member3.id}
          ]
        )

      assert Balance.fill_members_balance([member1, member2, member3]) ==
               [
                 %{member1 | balance: Money.new(100, :EUR)},
                 %{member2 | balance: Money.new(100, :EUR)},
                 %{member3 | balance: Money.new(-200, :EUR)}
               ]
    end

    test "takes peer weight into account", %{book: book} do
      member1 = book_member_fixture(book, user_id: user_fixture().id)
      member2 = book_member_fixture(book, user_id: user_fixture().id)
      member3 = book_member_fixture(book, user_id: user_fixture().id)

      _transfer =
        money_transfer_fixture(book,
          tenant_id: member1.id,
          amount: Money.new(6, :EUR),
          peers: [
            %{member_id: member1.id, weight: 3},
            %{member_id: member2.id, weight: 2},
            %{member_id: member3.id}
          ]
        )

      assert Balance.fill_members_balance([member1, member2, member3]) ==
               [
                 %{member1 | balance: Money.new(3, :EUR)},
                 %{member2 | balance: Money.new(-2, :EUR)},
                 %{member3 | balance: Money.new(-1, :EUR)}
               ]
    end

    # FIXME correctly divide non round amounts
    # test "correctly divide non round amounts", %{book: book} do
    #   member1 = book_member_fixture(book, user_id: user_fixture().id)
    #   member2 = book_member_fixture(book, user_id: user_fixture().id)

    #   transfer =
    #     money_transfer_fixture(book,
    #       tenant_id: member1.id,
    #       amount: Money.new(3, :EUR),
    #       peers: [%{member_id: member1.id}, %{member_id: member2.id}]
    #     )

    #   assert Balance.fill_members_balance([member1, member2]) == [
    #            %{member1 | balance: Money.new(1, :EUR)},
    #            %{member2 | balance: Money.new(-2, :EUR)}
    #          ]
    # end

    test "weight transfer amount using peers income #1", %{book: book} do
      user1 = user_fixture()
      _balance_config1 = user_balance_config_fixture(user1, annual_income: 1)
      member1 = book_member_fixture(book, user_id: user1.id)

      user2 = user_fixture()
      _balance_config2 = user_balance_config_fixture(user2, annual_income: 2)
      member2 = book_member_fixture(book, user_id: user2.id)

      _transfer =
        money_transfer_fixture(book,
          tenant_id: member1.id,
          balance_params: %{means_code: :weight_by_income},
          amount: Money.new(30, :EUR),
          peers: [%{member_id: member1.id}, %{member_id: member2.id}]
        )

      assert Balance.fill_members_balance([member1, member2]) == [
               %{member1 | balance: Money.new(20, :EUR)},
               %{member2 | balance: Money.new(-20, :EUR)}
             ]
    end

    test "weight transfer amount using peers income #2", %{book: book} do
      user1 = user_fixture()
      _balance_config1 = user_balance_config_fixture(user1, annual_income: 2)
      member1 = book_member_fixture(book, user_id: user1.id)

      user2 = user_fixture()
      _balance_config2 = user_balance_config_fixture(user2, annual_income: 2)
      member2 = book_member_fixture(book, user_id: user2.id)

      user3 = user_fixture()
      _balance_config3 = user_balance_config_fixture(user3, annual_income: 2)
      member3 = book_member_fixture(book, user_id: user3.id)

      user4 = user_fixture()
      _balance_config4 = user_balance_config_fixture(user4, annual_income: 3)
      member4 = book_member_fixture(book, user_id: user4.id)

      _transfer =
        money_transfer_fixture(book,
          tenant_id: member1.id,
          balance_params: %{means_code: :weight_by_income},
          amount: Money.new(9, :EUR),
          peers: [
            %{member_id: member1.id},
            %{member_id: member2.id},
            %{member_id: member3.id},
            %{member_id: member4.id}
          ]
        )

      assert Balance.fill_members_balance([member1, member2, member3, member4]) ==
               [
                 %{member1 | balance: Money.new(7, :EUR)},
                 %{member2 | balance: Money.new(-2, :EUR)},
                 %{member3 | balance: Money.new(-2, :EUR)},
                 %{member4 | balance: Money.new(-3, :EUR)}
               ]
    end

    test "weighting by incomes takes user-defined weight into account", %{book: book} do
      user1 = user_fixture()
      _balance_config1 = user_balance_config_fixture(user1, annual_income: 1)
      member1 = book_member_fixture(book, user_id: user1.id)

      user2 = user_fixture()
      _balance_config2 = user_balance_config_fixture(user2, annual_income: 2)
      member2 = book_member_fixture(book, user_id: user2.id)

      user3 = user_fixture()
      _balance_config3 = user_balance_config_fixture(user3, annual_income: 3)
      member3 = book_member_fixture(book, user_id: user3.id)

      _transfer =
        money_transfer_fixture(book,
          tenant_id: member1.id,
          balance_params: %{means_code: :weight_by_income},
          amount: Money.new(100, :EUR),
          peers: [
            %{member_id: member1.id, weight: Decimal.new(1)},
            %{member_id: member2.id, weight: Decimal.new(2)},
            %{member_id: member3.id, weight: Decimal.new(3)}
          ]
        )

      assert Balance.fill_members_balance([member1, member2, member3]) ==
               [
                 %{member1 | balance: Money.new(93, :EUR)},
                 %{member2 | balance: Money.new(-29, :EUR)},
                 %{member3 | balance: Money.new(-64, :EUR)}
               ]
    end

    test "fails if a user config appropriate fields aren't set", %{book: book} do
      user1 = user_fixture()
      member1 = book_member_fixture(book, user_id: user1.id)

      user2 = user_fixture()
      _balance_config2 = user_balance_config_fixture(user2, annual_income: 1)
      member2 = book_member_fixture(book, user_id: user2.id)

      user3 = user_fixture()
      _balance_config3 = user_balance_config_fixture(user3, annual_income: 1)
      member3 = book_member_fixture(book, user_id: user3.id)

      _transfer1 =
        money_transfer_fixture(book,
          tenant_id: member1.id,
          balance_params: %{means_code: :weight_by_income},
          amount: Money.new(30, :EUR),
          peers: [%{member_id: member1.id}, %{member_id: member2.id}]
        )

      _transfer2 =
        money_transfer_fixture(book,
          tenant_id: member1.id,
          balance_params: %{means_code: :weight_by_income},
          amount: Money.new(40, :EUR),
          peers: [%{member_id: member2.id}, %{member_id: member3.id}]
        )

      assert Balance.fill_members_balance([member1, member2, member3]) == [
               %{member1 | balance: {:error, ["some members did not set their annual income"]}},
               %{member2 | balance: {:error, ["some members did not set their annual income"]}},
               %{member3 | balance: Money.new(-20, :EUR)}
             ]
    end

    test "does not crash if the book is correctly balanced", %{book: book} do
      member1 = book_member_fixture(book, user_id: user_fixture().id)
      member2 = book_member_fixture(book, user_id: user_fixture().id)
      member3 = book_member_fixture(book, user_id: user_fixture().id)

      _transfer1 =
        money_transfer_fixture(book,
          amount: Money.new(300, :EUR),
          tenant_id: member1.id,
          peers: [
            %{member_id: member1.id},
            %{member_id: member2.id},
            %{member_id: member3.id}
          ]
        )

      _reimbursement1 =
        money_transfer_fixture(book,
          amount: Money.new(100, :EUR),
          type: :reimbursement,
          tenant_id: member1.id,
          peers: [%{member_id: member2.id}]
        )

      _reimbursement1 =
        money_transfer_fixture(book,
          amount: Money.new(100, :EUR),
          type: :reimbursement,
          tenant_id: member1.id,
          peers: [%{member_id: member3.id}]
        )

      assert Balance.fill_members_balance([member1, member2, member3]) ==
               [
                 %{member1 | balance: Money.new(0, :EUR)},
                 %{member2 | balance: Money.new(0, :EUR)},
                 %{member3 | balance: Money.new(0, :EUR)}
               ]
    end
  end

  describe "transactions/1" do
    setup do
      %{book: book_fixture()}
    end

    test "creates transactions to balance members money #1", %{book: book} do
      member1 =
        book_member_fixture(book, user_id: user_fixture().id, balance: Money.new(10, :EUR))

      member2 =
        book_member_fixture(book, user_id: user_fixture().id, balance: Money.new(-10, :EUR))

      member3 = book_member_fixture(book, user_id: user_fixture().id, balance: Money.new(0, :EUR))

      assert {:ok, transactions} = Balance.transactions([member1, member2, member3])

      assert transactions_equal?(transactions, [
               %{from: member2, to: member1, amount: Money.new(10, :EUR)}
             ])
    end

    test "creates transactions to balance members money #2", %{book: book} do
      member1 =
        book_member_fixture(book, user_id: user_fixture().id, balance: Money.new(120, :EUR))

      member2 =
        book_member_fixture(book, user_id: user_fixture().id, balance: Money.new(33, :EUR))

      member3 =
        book_member_fixture(book, user_id: user_fixture().id, balance: Money.new(-12, :EUR))

      member4 =
        book_member_fixture(book, user_id: user_fixture().id, balance: Money.new(-121, :EUR))

      member5 =
        book_member_fixture(book, user_id: user_fixture().id, balance: Money.new(-20, :EUR))

      assert {:ok, transactions} =
               Balance.transactions([member1, member2, member3, member4, member5])

      assert transactions_equal?(transactions, [
               %{from: member5, to: member2, amount: Money.new(20, :EUR)},
               %{from: member4, to: member2, amount: Money.new(13, :EUR)},
               %{from: member4, to: member1, amount: Money.new(108, :EUR)},
               %{from: member3, to: member1, amount: Money.new(12, :EUR)}
             ])
    end

    test "retuns an empty array if given no members", _context do
      assert Balance.transactions([]) == {:ok, []}
    end

    test "returns :error when the balance of a member is corrupted", %{book: book} do
      member1 =
        book_member_fixture(book, user_id: user_fixture().id, balance: Money.new(10, :EUR))

      member2 =
        book_member_fixture(book,
          user_id: user_fixture().id,
          balance: {:error, "could not compute balance"}
        )

      assert Balance.transactions([member1, member2]) == :error
    end

    defp transactions_equal?(transactions1, transactions2) do
      Enum.map(transactions1, &serialize_transaction/1) ==
        Enum.map(transactions2, &serialize_transaction/1)
    end

    defp serialize_transaction(transaction) do
      %{transaction | from: transaction.from.id, to: transaction.to.id}
    end
  end
end
