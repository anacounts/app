defmodule App.Accounts.Balance.Means.DivideEquallyTest do
  use App.DataCase, async: true

  import App.AccountsFixtures
  import App.AuthFixtures
  import App.BooksFixtures
  import App.TransfersFixtures

  alias App.Accounts.Balance.Means.DivideEqually

  describe "balance_transfer_by_peer/1" do
    setup :setup_user_fixture
    setup :setup_book_fixture
    setup :setup_book_member_fixture

    test "balances transfer amount among 2 peers", %{
      book: %{members: [member1]} = book,
      book_member: member2
    } do
      transfer =
        money_transfer_fixture(
          book_id: book.id,
          tenant_id: member1.id,
          amount: Money.new(2, :EUR),
          peers: [%{member_id: member1.id}, %{member_id: member2.id}]
        )

      assert DivideEqually.balance_transfer_by_peer(transfer) ==
               {:ok,
                [
                  %{
                    amount: Money.new(1, :EUR),
                    from: member1.id,
                    to: member1.id,
                    transfer_id: transfer.id
                  },
                  %{
                    amount: Money.new(1, :EUR),
                    from: member2.id,
                    to: member1.id,
                    transfer_id: transfer.id
                  }
                ]}
    end

    test "balances transfer amount among multiple peers", %{book: %{members: [member1]} = book} do
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
          amount: Money.new(4, :EUR),
          peers: [
            %{member_id: member1.id},
            %{member_id: member2.id},
            %{member_id: member3.id},
            %{member_id: member4.id}
          ]
        )

      assert DivideEqually.balance_transfer_by_peer(transfer) ==
               {:ok,
                [
                  %{
                    amount: Money.new(1, :EUR),
                    from: member1.id,
                    to: member1.id,
                    transfer_id: transfer.id
                  },
                  %{
                    amount: Money.new(1, :EUR),
                    from: member2.id,
                    to: member1.id,
                    transfer_id: transfer.id
                  },
                  %{
                    amount: Money.new(1, :EUR),
                    from: member3.id,
                    to: member1.id,
                    transfer_id: transfer.id
                  },
                  %{
                    amount: Money.new(1, :EUR),
                    from: member4.id,
                    to: member1.id,
                    transfer_id: transfer.id
                  }
                ]}
    end

    test "takes peer weight into account", %{book: %{members: [member1]} = book} do
      user2 = user_fixture()
      member2 = book_member_fixture(book, user2)

      user3 = user_fixture()
      member3 = book_member_fixture(book, user3)

      transfer =
        money_transfer_fixture(
          book_id: book.id,
          tenant_id: member1.id,
          amount: Money.new(6, :EUR),
          peers: [
            %{member_id: member1.id, weight: 3},
            %{member_id: member2.id, weight: 2},
            %{member_id: member3.id}
          ]
        )

      assert DivideEqually.balance_transfer_by_peer(transfer) ==
               {:ok,
                [
                  %{
                    amount: Money.new(3, :EUR),
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
                    amount: Money.new(1, :EUR),
                    from: member3.id,
                    to: member1.id,
                    transfer_id: transfer.id
                  }
                ]}
    end

    # FIXME correctly divide non round amounts
    # test "correctly divide non round amounts", %{book: %{members: [member1]} = book} do
    #   user2 = user_fixture()
    #   member2 = book_member_fixture(book, user2)

    #   transfer =
    #     money_transfer_fixture(
    #       book_id: book.id,
    #       tenant_id: member1.id,
    #       amount: Money.new(3, :EUR),
    #       peers: [%{member_id: member1.id}, %{member_id: member2.id}]
    #     )

    #   assert DivideEqually.balance_transfer_by_peer(transfer) ==
    #            {:ok,
    #             [
    #               %{
    #                 amount: Money.new(2, :EUR),
    #                 from: member1.id,
    #                 to: member1.id,
    #                 transfer_id: transfer.id
    #               },
    #               %{
    #                 amount: Money.new(1, :EUR),
    #                 from: member2.id,
    #                 to: member1.id,
    #                 transfer_id: transfer.id
    #               }
    #             ]}
    # end
  end
end
