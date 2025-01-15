defmodule App.Balance.CacheUpdaterWorkerTest do
  use App.DataCase, async: true

  import App.Books.MembersFixtures
  import App.BooksFixtures
  import App.TransfersFixtures

  alias App.Balance.CacheUpdaterWorker

  describe "update_book_balance/1" do
    test "creates an Oban job when the book_id" do
      book_id = 123

      {:ok, job} = CacheUpdaterWorker.update_book_balance(book_id)
      assert job.queue == "balance"
      assert job.args == %{book_id: book_id}
    end

    test "overrides previous existing job" do
      book_id = 123

      {:ok, %{id: id}} = CacheUpdaterWorker.update_book_balance(book_id)
      {:ok, %{id: ^id}} = CacheUpdaterWorker.update_book_balance(book_id)

      jobs = all_enqueued(worker: CacheUpdaterWorker)
      assert length(jobs) == 1
    end

    test "does not override jobs with different book_id" do
      book_id1 = 123
      book_id2 = 456

      {:ok, %{id: id1}} = CacheUpdaterWorker.update_book_balance(book_id1)
      {:ok, %{id: id2}} = CacheUpdaterWorker.update_book_balance(book_id2)

      assert id1 != id2

      jobs = all_enqueued(worker: CacheUpdaterWorker)
      assert length(jobs) == 2
    end
  end

  describe "perform/1" do
    test "updates the book members balance" do
      book = book_fixture()
      member1 = book_member_fixture(book)
      member2 = book_member_fixture(book)
      member3 = book_member_fixture(book)

      transfer = money_transfer_fixture(book, tenant_id: member1.id, amount: Money.new(:EUR, 333))
      _peer1 = peer_fixture(transfer, member_id: member1.id)
      _peer2 = peer_fixture(transfer, member_id: member2.id)
      _peer3 = peer_fixture(transfer, member_id: member3.id)

      perform_job(CacheUpdaterWorker, %{book_id: book.id})

      member1 = get_member_balance(member1.id)
      assert Money.equal?(member1.balance, Money.new(:EUR, 222))
      assert member1.balance_errors == []
      member2 = get_member_balance(member2.id)
      assert Money.equal?(member2.balance, Money.new(:EUR, "-111.00"))
      assert member2.balance_errors == []
      member3 = get_member_balance(member3.id)
      assert Money.equal?(member3.balance, Money.new(:EUR, "-111.00"))
      assert member3.balance_errors == []
    end

    # TODO once the BookMember `:balance` field is not virtual anymore,
    # remove this request and use the BookMember fields directly
    defp get_member_balance(member_id) do
      from(book_member in "book_members",
        where: book_member.id == ^member_id,
        select: %{
          balance: book_member.balance,
          balance_errors: book_member.balance_errors
        }
      )
      |> Repo.one!()
      |> Map.update!(:balance, fn raw ->
        {:ok, balance} = Money.Ecto.Composite.Type.load(raw)
        balance
      end)
    end
  end
end
