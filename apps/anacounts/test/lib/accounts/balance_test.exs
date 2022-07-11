defmodule Anacounts.Accounts.BalanceTest do
  use Anacounts.DataCase, async: true

  import Anacounts.AccountsFixtures
  import Anacounts.AuthFixtures
  import Anacounts.TransfersFixtures

  alias Anacounts.Accounts.Balance

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
                 member.id => %Money{amount: 5, currency: :EUR},
                 other_member.id => %Money{amount: -5, currency: :EUR}
               },
               transactions: [
                 %{
                   amount: %Money{amount: 5, currency: :EUR},
                   from: other_member.id,
                   to: member.id
                 }
               ]
             }
    end
  end
end
