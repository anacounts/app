defmodule App.BalanceTest do
  use App.DataCase, async: true

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
end
