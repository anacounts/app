defmodule App.BalanceTest do
  use App.DataCase, async: true

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
      member1 = book_member_fixture(book)
      member2 = book_member_fixture(book)

      _money_transfer =
        deprecated_money_transfer_fixture(book,
          amount: Money.new!(:EUR, 10),
          tenant_id: member1.id,
          peers: [%{member_id: member1.id}, %{member_id: member2.id}]
        )

      [member1, member2] = Balance.fill_members_balance([member1, member2])
      assert Money.equal?(member1.balance, Money.new!(:EUR, 5))
      assert Money.equal?(member2.balance, Money.new!(:EUR, -5))
    end

    test "balances multiple transfers correctly #1", %{book: book} do
      member1 = book_member_fixture(book)
      member2 = book_member_fixture(book)
      member3 = book_member_fixture(book)
      member4 = book_member_fixture(book)

      _transfer1 =
        deprecated_money_transfer_fixture(book,
          amount: Money.new!(:EUR, 400),
          tenant_id: member1.id,
          peers: [
            %{member_id: member1.id},
            %{member_id: member2.id},
            %{member_id: member3.id},
            %{member_id: member4.id}
          ]
        )

      _transfer2 =
        deprecated_money_transfer_fixture(book,
          amount: Money.new!(:EUR, 400),
          tenant_id: member2.id,
          peers: [
            %{member_id: member1.id},
            %{member_id: member2.id},
            %{member_id: member3.id},
            %{member_id: member4.id}
          ]
        )

      [member1, member2, member3, member4] =
        Balance.fill_members_balance([member1, member2, member3, member4])

      assert Money.equal?(member1.balance, Money.new!(:EUR, 200))
      assert Money.equal?(member2.balance, Money.new!(:EUR, 200))
      assert Money.equal?(member3.balance, Money.new!(:EUR, -200))
      assert Money.equal?(member4.balance, Money.new!(:EUR, -200))
    end

    test "balances multiple transfers correctly #2", %{book: book} do
      member1 = book_member_fixture(book)
      member2 = book_member_fixture(book)
      member3 = book_member_fixture(book)

      _transfer1 =
        deprecated_money_transfer_fixture(book,
          amount: Money.new!(:EUR, 300),
          tenant_id: member1.id,
          peers: [
            %{member_id: member1.id},
            %{member_id: member2.id},
            %{member_id: member3.id}
          ]
        )

      _transfer2 =
        deprecated_money_transfer_fixture(book,
          amount: Money.new!(:EUR, 300),
          tenant_id: member2.id,
          peers: [
            %{member_id: member1.id},
            %{member_id: member2.id},
            %{member_id: member3.id}
          ]
        )

      [member1, member2, member3] = Balance.fill_members_balance([member1, member2, member3])
      assert Money.equal?(member1.balance, Money.new!(:EUR, 100))
      assert Money.equal?(member2.balance, Money.new!(:EUR, 100))
      assert Money.equal?(member3.balance, Money.new!(:EUR, -200))
    end

    test "takes peer weight into account", %{book: book} do
      member1 = book_member_fixture(book)
      member2 = book_member_fixture(book)
      member3 = book_member_fixture(book)

      _transfer =
        deprecated_money_transfer_fixture(book,
          tenant_id: member1.id,
          amount: Money.new!(:EUR, 6),
          peers: [
            %{member_id: member1.id, weight: 3},
            %{member_id: member2.id, weight: 2},
            %{member_id: member3.id}
          ]
        )

      [member1, member2, member3] = Balance.fill_members_balance([member1, member2, member3])
      assert Money.equal?(member1.balance, Money.new!(:EUR, 3))
      assert Money.equal?(member2.balance, Money.new!(:EUR, -2))
      assert Money.equal?(member3.balance, Money.new!(:EUR, -1))
    end

    test "correctly divide non round amounts", %{book: book} do
      member1 = book_member_fixture(book)
      member2 = book_member_fixture(book)

      _transfer =
        deprecated_money_transfer_fixture(book,
          tenant_id: member1.id,
          amount: Money.new!(:EUR, "0.03"),
          peers: [%{member_id: member1.id}, %{member_id: member2.id}]
        )

      assert Balance.fill_members_balance([member1, member2]) == [
               %{member1 | balance: Money.new!(:EUR, "0.01")},
               %{member2 | balance: Money.new!(:EUR, "-0.01")}
             ]
    end

    test "weight transfer amount using peers income #1", %{book: book} do
      member1 = book_member_fixture(book)
      _balance_config1 = member_balance_config_fixture(member1, annual_income: 1)

      member2 = book_member_fixture(book)
      _balance_config2 = member_balance_config_fixture(member2, annual_income: 2)

      _transfer =
        deprecated_money_transfer_fixture(book,
          tenant_id: member1.id,
          balance_params: %{means_code: :weight_by_income},
          amount: Money.new!(:EUR, 30),
          peers: [%{member_id: member1.id}, %{member_id: member2.id}]
        )

      [member1, member2] = Balance.fill_members_balance([member1, member2])

      assert Money.equal?(member1.balance, Money.new!(:EUR, 20))
      assert Money.equal?(member2.balance, Money.new!(:EUR, -20))
    end

    test "weight transfer amount using peers income #2", %{book: book} do
      member1 = book_member_fixture(book)
      _balance_config1 = member_balance_config_fixture(member1, annual_income: 2)

      member2 = book_member_fixture(book)
      _balance_config2 = member_balance_config_fixture(member2, annual_income: 2)

      member3 = book_member_fixture(book)
      _balance_config3 = member_balance_config_fixture(member3, annual_income: 2)

      member4 = book_member_fixture(book)
      _balance_config4 = member_balance_config_fixture(member4, annual_income: 3)

      _transfer =
        deprecated_money_transfer_fixture(book,
          tenant_id: member1.id,
          balance_params: %{means_code: :weight_by_income},
          amount: Money.new!(:EUR, 9),
          peers: [
            %{member_id: member1.id},
            %{member_id: member2.id},
            %{member_id: member3.id},
            %{member_id: member4.id}
          ]
        )

      [member1, member2, member3, member4] =
        Balance.fill_members_balance([member1, member2, member3, member4])

      assert Money.equal?(member1.balance, Money.new!(:EUR, 7))
      assert Money.equal?(member2.balance, Money.new!(:EUR, -2))
      assert Money.equal?(member3.balance, Money.new!(:EUR, -2))
      assert Money.equal?(member4.balance, Money.new!(:EUR, -3))
    end

    test "weighting by incomes takes user-defined weight into account", %{book: book} do
      member1 = book_member_fixture(book)
      _balance_config1 = member_balance_config_fixture(member1, annual_income: 1)

      member2 = book_member_fixture(book)
      _balance_config2 = member_balance_config_fixture(member2, annual_income: 2)

      member3 = book_member_fixture(book)
      _balance_config3 = member_balance_config_fixture(member3, annual_income: 3)

      _transfer =
        deprecated_money_transfer_fixture(book,
          tenant_id: member1.id,
          balance_params: %{means_code: :weight_by_income},
          amount: Money.new!(:EUR, 100),
          peers: [
            %{member_id: member1.id, weight: Decimal.new(1)},
            %{member_id: member2.id, weight: Decimal.new(2)},
            %{member_id: member3.id, weight: Decimal.new(3)}
          ]
        )

      [member1, member2, member3] = Balance.fill_members_balance([member1, member2, member3])
      assert Money.equal?(member1.balance, Money.new!(:EUR, "92.86"))
      assert Money.equal?(member2.balance, Money.new!(:EUR, "-28.56"))
      assert Money.equal?(member3.balance, Money.new!(:EUR, "-64.30"))
    end

    test "fails if a user config appropriate fields aren't set", %{book: book} do
      member1 = book_member_fixture(book, display_name: "member1")
      _balance_config1 = member_balance_config_fixture(member1, annual_income: nil)

      member2 = book_member_fixture(book)
      _balance_config2 = member_balance_config_fixture(member2, annual_income: 1)

      member3 = book_member_fixture(book)
      _balance_config3 = member_balance_config_fixture(member3, annual_income: 1)

      _transfer1 =
        deprecated_money_transfer_fixture(book,
          tenant_id: member1.id,
          balance_params: %{means_code: :weight_by_income},
          amount: Money.new!(:EUR, 30),
          peers: [%{member_id: member1.id}, %{member_id: member2.id}]
        )

      _transfer2 =
        deprecated_money_transfer_fixture(book,
          tenant_id: member1.id,
          balance_params: %{means_code: :weight_by_income},
          amount: Money.new!(:EUR, 40),
          peers: [%{member_id: member2.id}, %{member_id: member3.id}]
        )

      [member1, member2, member3] = Balance.fill_members_balance([member1, member2, member3])

      assert member1.balance ==
               {:error,
                [
                  %{
                    message: "member1 did not set their annual income",
                    uniq_hash: "income_not_set_#{member1.id}"
                  }
                ]}

      assert member2.balance ==
               {:error,
                [
                  %{
                    message: "member1 did not set their annual income",
                    uniq_hash: "income_not_set_#{member1.id}"
                  }
                ]}

      assert Money.equal?(member3.balance, Money.new!(:EUR, -20))
    end

    test "does not crash if the book is correctly balanced", %{book: book} do
      member1 = book_member_fixture(book)
      member2 = book_member_fixture(book)
      member3 = book_member_fixture(book)

      _transfer1 =
        deprecated_money_transfer_fixture(book,
          amount: Money.new!(:EUR, 300),
          tenant_id: member1.id,
          peers: [
            %{member_id: member1.id},
            %{member_id: member2.id},
            %{member_id: member3.id}
          ]
        )

      _reimbursement1 =
        deprecated_money_transfer_fixture(book,
          amount: Money.new!(:EUR, 100),
          type: :reimbursement,
          tenant_id: member1.id,
          peers: [%{member_id: member2.id}]
        )

      _reimbursement1 =
        deprecated_money_transfer_fixture(book,
          amount: Money.new!(:EUR, 100),
          type: :reimbursement,
          tenant_id: member1.id,
          peers: [%{member_id: member3.id}]
        )

      [member1, member2, member3] = Balance.fill_members_balance([member1, member2, member3])
      assert Money.equal?(member1.balance, Money.new!(:EUR, 0))
      assert Money.equal?(member2.balance, Money.new!(:EUR, 0))
      assert Money.equal?(member3.balance, Money.new!(:EUR, 0))
    end
  end

  describe "transactions/1" do
    setup do
      %{book: book_fixture()}
    end

    test "creates transactions to balance members money #1", %{book: book} do
      member1 = book_member_fixture(book, balance: Money.new!(:EUR, 10))
      member2 = book_member_fixture(book, balance: Money.new!(:EUR, -10))
      member3 = book_member_fixture(book, balance: Money.new!(:EUR, 0))

      assert {:ok, transactions} = Balance.transactions([member1, member2, member3])

      assert transactions_equal?(transactions, [
               %{
                 id: "#{member2.id}-#{member1.id}",
                 from: member2,
                 to: member1,
                 amount: Money.new!(:EUR, 10)
               }
             ])
    end

    test "creates transactions to balance members money #2", %{book: book} do
      member1 = book_member_fixture(book, balance: Money.new!(:EUR, 120))
      member2 = book_member_fixture(book, balance: Money.new!(:EUR, 33))
      member3 = book_member_fixture(book, balance: Money.new!(:EUR, -12))
      member4 = book_member_fixture(book, balance: Money.new!(:EUR, -121))
      member5 = book_member_fixture(book, balance: Money.new!(:EUR, -20))

      assert {:ok, transactions} =
               Balance.transactions([member1, member2, member3, member4, member5])

      assert transactions_equal?(transactions, [
               %{
                 id: "#{member5.id}-#{member2.id}",
                 from: member5,
                 to: member2,
                 amount: Money.new!(:EUR, 20)
               },
               %{
                 id: "#{member4.id}-#{member2.id}",
                 from: member4,
                 to: member2,
                 amount: Money.new!(:EUR, 13)
               },
               %{
                 id: "#{member4.id}-#{member1.id}",
                 from: member4,
                 to: member1,
                 amount: Money.new!(:EUR, 108)
               },
               %{
                 id: "#{member3.id}-#{member1.id}",
                 from: member3,
                 to: member1,
                 amount: Money.new!(:EUR, 12)
               }
             ])
    end

    test "retuns an empty array if given no members", _context do
      assert Balance.transactions([]) == {:ok, []}
    end

    test "returns :error when the balance of a member is corrupted", %{book: book} do
      member1 = book_member_fixture(book, balance: Money.new!(:EUR, 10))
      member2 = book_member_fixture(book, balance: {:error, ["could not compute balance"]})

      assert Balance.transactions([member1, member2]) == {:error, ["could not compute balance"]}
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
