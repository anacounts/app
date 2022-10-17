defmodule App.Balance.Means.DivideEquallyTest do
  use App.DataCase, async: true

  import App.AuthFixtures
  import App.BooksFixtures
  import App.Books.MembersFixtures
  import App.TransfersFixtures

  alias App.Balance.Means.DivideEqually

  describe "balance_transfer_by_peer/1" do
    setup :book_with_member_context

    test "balances transfer amount among 2 peers", %{
      book: book,
      member: member1
    } do
      member2 = book_member_fixture(book, user_fixture())

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

    test "balances transfer amount among multiple peers", %{book: book, member: member1} do
      member2 = book_member_fixture(book, user_fixture())
      member3 = book_member_fixture(book, user_fixture())
      member4 = book_member_fixture(book, user_fixture())

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

    test "takes peer weight into account", %{book: book, member: member1} do
      member2 = book_member_fixture(book, user_fixture())
      member3 = book_member_fixture(book, user_fixture())

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
    # test "correctly divide non round amounts", %{book: book, member: member1} do
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
