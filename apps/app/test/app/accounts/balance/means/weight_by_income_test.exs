defmodule App.Accounts.Balance.Means.WeightByIncomeTest do
  use App.DataCase, async: true

  import App.AccountsFixtures
  import App.Accounts.BalanceFixtures
  import App.AuthFixtures
  import App.BooksFixtures
  import App.TransfersFixtures

  alias App.Accounts.Balance.Means.WeightByIncome

  describe "balance_transfer_by_peer/1" do
    setup :setup_user_fixture
    setup :setup_book_fixture
    setup :setup_book_member_fixture

    test "balances transfer amount among 2 peers", %{
      book: %{members: [member1]} = book,
      user: user1,
      book_member: member2,
      book_member_user: user2
    } do
      transfer =
        money_transfer_fixture(
          book_id: book.id,
          tenant_id: member1.id,
          amount: Money.new(30, :EUR),
          peers: [%{member_id: member1.id}, %{member_id: member2.id}]
        )

      balance_user_params_fixtures(user1, means_code: :weight_by_income, params: %{income: 1})
      balance_user_params_fixtures(user2, means_code: :weight_by_income, params: %{income: 2})

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

    test "balance among multiple peers", %{user: user1, book: %{members: [member1]} = book} do
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

      balance_user_params_fixtures(user1, means_code: :weight_by_income, params: %{income: 1})
      balance_user_params_fixtures(user2, means_code: :weight_by_income, params: %{income: 2})
      balance_user_params_fixtures(user3, means_code: :weight_by_income, params: %{income: 2})
      balance_user_params_fixtures(user4, means_code: :weight_by_income, params: %{income: 3})

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

    test "takes weight into account", %{user: user1, book: %{members: [member1]} = book} do
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

      balance_user_params_fixtures(user1, means_code: :weight_by_income, params: %{income: 1})
      balance_user_params_fixtures(user2, means_code: :weight_by_income, params: %{income: 1})

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

    test "takes weight into account for 3 peers", %{
      user: user1,
      book: %{members: [member1]} = book
    } do
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

      balance_user_params_fixtures(user1, means_code: :weight_by_income, params: %{income: 1})
      balance_user_params_fixtures(user2, means_code: :weight_by_income, params: %{income: 2})
      balance_user_params_fixtures(user3, means_code: :weight_by_income, params: %{income: 3})

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

    test "fails if a user params isn't available", %{
      book: %{members: [member1]} = book,
      book_member: member2
    } do
      money_transfer =
        money_transfer_fixture(
          book_id: book.id,
          tenant_id: member1.id,
          amount: Money.new(30, :EUR),
          peers: [%{member_id: member1.id}, %{member_id: member2.id}]
        )

      assert WeightByIncome.balance_transfer_by_peer(money_transfer) ==
               {:error,
                [
                  " did not parameter their income for \"Weight By Income\"",
                  " did not parameter their income for \"Weight By Income\""
                ]}
    end
  end
end
