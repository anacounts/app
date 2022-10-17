defmodule App.Balance.Means.WeightByIncomeTest do
  use App.DataCase, async: true

  import App.Balance.ConfigFixtures
  import App.AuthFixtures
  import App.BooksFixtures
  import App.Books.MembersFixtures
  import App.TransfersFixtures

  alias App.Balance.Means.WeightByIncome

  describe "balance_transfer_by_peer/1" do
    setup :book_with_member_context

    test "balances transfer amount among 2 peers", %{book: book, user: user1, member: member1} do
      user2 = user_fixture()
      member2 = book_member_fixture(book, user2)

      transfer =
        money_transfer_fixture(
          book_id: book.id,
          tenant_id: member1.id,
          amount: Money.new(30, :EUR),
          peers: [%{member_id: member1.id}, %{member_id: member2.id}]
        )

      user_balance_config_fixture(user1, annual_income: 1)
      user_balance_config_fixture(user2, annual_income: 2)

      assert WeightByIncome.balance_transfer_by_peer(transfer) ==
               {:ok,
                [
                  %{
                    amount: Money.new(10, :EUR),
                    from: member1.id,
                    to: member1.id,
                    transfer_id: transfer.id
                  },
                  %{
                    amount: Money.new(20, :EUR),
                    from: member2.id,
                    to: member1.id,
                    transfer_id: transfer.id
                  }
                ]}
    end

    test "balance among multiple peers", %{book: book, user: user1, member: member1} do
      user2 = user_fixture()
      member2 = book_member_fixture(book, user2)

      user3 = user_fixture()
      member3 = book_member_fixture(book, user3)

      user4 = user_fixture()
      member4 = book_member_fixture(book, user4)

      transfer =
        money_transfer_fixture(
          book_id: book.id,
          tenant_id: member1.id,
          amount: Money.new(8, :EUR),
          peers: [
            %{member_id: member1.id},
            %{member_id: member2.id},
            %{member_id: member3.id},
            %{member_id: member4.id}
          ]
        )

      user_balance_config_fixture(user1, annual_income: 1)
      user_balance_config_fixture(user2, annual_income: 2)
      user_balance_config_fixture(user3, annual_income: 2)
      user_balance_config_fixture(user4, annual_income: 3)

      assert WeightByIncome.balance_transfer_by_peer(transfer) ==
               {:ok,
                [
                  %{
                    amount: Money.new(1, :EUR),
                    from: member1.id,
                    to: member1.id,
                    transfer_id: transfer.id
                  },
                  %{
                    amount: Money.new(2, :EUR),
                    from: member2.id,
                    to: member1.id,
                    transfer_id: transfer.id
                  },
                  %{
                    amount: Money.new(2, :EUR),
                    from: member3.id,
                    to: member1.id,
                    transfer_id: transfer.id
                  },
                  %{
                    amount: Money.new(3, :EUR),
                    from: member4.id,
                    to: member1.id,
                    transfer_id: transfer.id
                  }
                ]}
    end

    test "takes weight into account", %{book: book, member: member1, user: user1} do
      user2 = user_fixture()
      member2 = book_member_fixture(book, user2)

      transfer =
        money_transfer_fixture(
          book_id: book.id,
          tenant_id: member1.id,
          amount: Money.new(3, :EUR),
          peers: [
            %{member_id: member1.id, weight: Decimal.new(1)},
            %{member_id: member2.id, weight: Decimal.new(2)}
          ]
        )

      user_balance_config_fixture(user1, annual_income: 1)
      user_balance_config_fixture(user2, annual_income: 1)

      assert WeightByIncome.balance_transfer_by_peer(transfer) ==
               {:ok,
                [
                  %{
                    amount: Money.new(1, :EUR),
                    from: member1.id,
                    to: member1.id,
                    transfer_id: transfer.id
                  },
                  %{
                    amount: Money.new(2, :EUR),
                    from: member2.id,
                    to: member1.id,
                    transfer_id: transfer.id
                  }
                ]}
    end

    test "takes weight into account for 3 peers", %{book: book, user: user1, member: member1} do
      user2 = user_fixture()
      member2 = book_member_fixture(book, user2)

      user3 = user_fixture()
      member3 = book_member_fixture(book, user3)

      transfer =
        money_transfer_fixture(
          book_id: book.id,
          tenant_id: member1.id,
          amount: Money.new(100, :EUR),
          peers: [
            %{member_id: member1.id, weight: Decimal.new(1)},
            %{member_id: member2.id, weight: Decimal.new(2)},
            %{member_id: member3.id, weight: Decimal.new(3)}
          ]
        )

      user_balance_config_fixture(user1, annual_income: 1)
      user_balance_config_fixture(user2, annual_income: 2)
      user_balance_config_fixture(user3, annual_income: 3)

      assert WeightByIncome.balance_transfer_by_peer(transfer) ==
               {:ok,
                [
                  %{
                    amount: Money.new(7, :EUR),
                    from: member1.id,
                    to: member1.id,
                    transfer_id: transfer.id
                  },
                  %{
                    amount: Money.new(29, :EUR),
                    from: member2.id,
                    to: member1.id,
                    transfer_id: transfer.id
                  },
                  %{
                    amount: Money.new(64, :EUR),
                    from: member3.id,
                    to: member1.id,
                    transfer_id: transfer.id
                  }
                ]}
    end

    test "fails if a user config appropriate fields aren't set", %{book: book, member: member1} do
      user2 = user_fixture()
      member2 = book_member_fixture(book, user2)

      money_transfer =
        money_transfer_fixture(
          book_id: book.id,
          tenant_id: member1.id,
          amount: Money.new(30, :EUR),
          peers: [%{member_id: member1.id}, %{member_id: member2.id}]
        )

      user_balance_config_fixture(user2)

      assert WeightByIncome.balance_transfer_by_peer(money_transfer) ==
               {:error,
                [
                  " did not parameter their income for \"Weight By Income\"",
                  " did not parameter their income for \"Weight By Income\""
                ]}
    end
  end

  defp book_with_member_context(_context) do
    book = book_fixture()
    user = user_fixture()
    member = book_member_fixture(book, user)

    %{
      book: book,
      user: user,
      member: member
    }
  end
end
