defmodule App.TransfersTest do
  use App.DataCase, async: true

  import App.BalanceFixtures
  import App.AuthFixtures
  import App.BooksFixtures
  import App.Books.MembersFixtures
  import App.TransfersFixtures

  alias App.Repo

  alias App.Balance.TransferParams
  alias App.Books.Book
  alias App.Transfers
  alias App.Transfers.Peer

  describe "find_transfers_of_book/1" do
    setup :book_with_member_context

    test "find all transfers in book", %{book: book, member: member} do
      transfer = money_transfer_fixture(book, tenant_id: member.id)

      assert [found_transfer] = Transfers.list_transfers_of_book(book.id)
      assert found_transfer.id == transfer.id
    end

    test "finds transfers ordered by descending date", %{book: book, member: member} do
      transfer_after = money_transfer_fixture(book, tenant_id: member.id, date: ~D[2020-01-02])

      transfer_before = money_transfer_fixture(book, tenant_id: member.id, date: ~D[2020-01-01])

      assert [found_transfer1, found_transfer2] = Transfers.list_transfers_of_book(book.id)
      assert found_transfer1.id == transfer_after.id
      assert found_transfer2.id == transfer_before.id
    end
  end

  describe "create_money_transfer/1" do
    setup :book_with_member_context

    test "creates a money transfer", %{book: book, member: member} do
      assert {:ok, transfer} =
               Transfers.create_money_transfer(
                 book,
                 money_transfer_attributes(
                   tenant_id: member.id,
                   label: "A label",
                   amount: Money.new(1799, :EUR),
                   type: :payment,
                   date: ~D[2022-06-23]
                 )
               )

      assert transfer.label == "A label"
      assert transfer.amount == Money.new(1799, :EUR)
      assert transfer.type == :payment
      assert transfer.date == ~D[2022-06-23]
      assert transfer.balance_params == struct!(TransferParams, transfer_params_attributes())
      assert Enum.empty?(transfer.peers)
    end

    test "sets balance params", %{book: book, member: member} do
      assert {:ok, transfer} =
               Transfers.create_money_transfer(
                 book,
                 money_transfer_attributes(
                   tenant_id: member.id,
                   balance_params: transfer_params_attributes()
                 )
               )

      assert transfer.balance_params ==
               struct!(TransferParams, transfer_params_attributes())
    end

    test "creates peers along the way", %{book: book, member: member} do
      other_user = user_fixture()
      other_member = book_member_fixture(book, other_user)

      assert {:ok, transfer} =
               Transfers.create_money_transfer(
                 book,
                 money_transfer_attributes(
                   tenant_id: member.id,
                   peers: [
                     %{member_id: member.id},
                     %{member_id: other_member.id, weight: Decimal.new(3)}
                   ]
                 )
               )

      [peer1, peer2] = Enum.sort_by(transfer.peers, & &1.weight)

      assert peer1.member_id == member.id
      assert peer2.member_id == other_member.id
      assert peer2.weight == Decimal.new(3)
    end

    test "cannot create two peers for the same user", %{book: book, member: member} do
      assert {:error, changeset} =
               Transfers.create_money_transfer(
                 book,
                 money_transfer_attributes(
                   tenant_id: member.id,
                   peers: [%{member_id: member.id}, %{member_id: member.id}]
                 )
               )

      assert errors_on(changeset) == %{
               peers: [%{}, %{member_id: ["member is already a peer of this money transfer"]}]
             }
    end

    test "fails with invalid book_id", %{member: member} do
      assert {:error, changeset} =
               Transfers.create_money_transfer(
                 %Book{id: 0},
                 money_transfer_attributes(tenant_id: member.id)
               )

      assert errors_on(changeset) == %{book_id: ["does not exist"]}
    end

    test "fails with missing tenant_id", %{book: book} do
      assert {:error, changeset} =
               Transfers.create_money_transfer(book, money_transfer_attributes())

      assert errors_on(changeset) == %{tenant_id: ["can't be blank"]}
    end

    test "fails with invalid tenant_id", %{book: book} do
      assert {:error, changeset} =
               Transfers.create_money_transfer(book, money_transfer_attributes(tenant_id: 0))

      assert errors_on(changeset) == %{tenant_id: ["does not exist"]}
    end
  end

  describe "update_money_transfer/2" do
    setup :book_with_member_context
    setup :money_transfer_in_book_context

    test "updates the money transfer", %{book: book, user: user, money_transfer: money_transfer} do
      other_user = user_fixture()
      other_member = book_member_fixture(book, other_user)

      assert {:ok, updated} =
               Transfers.update_money_transfer(money_transfer, user, %{
                 label: "my very own label !",
                 amount: Money.new(299, :EUR),
                 type: :income,
                 date: ~D[2020-06-29],
                 balance_params: transfer_params_attributes(),
                 peers: [%{member_id: other_member.id}]
               })

      assert updated.label == "my very own label !"
      assert updated.amount == Money.new(299, :EUR)
      assert updated.type == :income
      assert updated.date == ~D[2020-06-29]

      assert updated.balance_params ==
               struct!(TransferParams, transfer_params_attributes())

      assert [peer] = updated.peers
      assert peer.member_id == other_member.id
    end

    test "returns an error if the user isn't a book member", %{money_transfer: money_transfer} do
      other_user = user_fixture()

      assert {:error, :unauthorized} =
               Transfers.update_money_transfer(money_transfer, other_user, %{
                 label: "my very own label !",
                 amount: Money.new(299, :EUR),
                 type: :income,
                 date: ~D[2020-06-29],
                 balance_params: transfer_params_attributes(),
                 peers: []
               })
    end

    test "does not update book", %{book: book, user: user, money_transfer: money_transfer} do
      other_book = book_fixture()

      assert {:ok, updated} =
               Transfers.update_money_transfer(money_transfer, user, %{
                 book_id: other_book.id
               })

      assert updated.book_id == book.id
    end

    test "updates existing peers", %{book: book, user: user, member: member} do
      money_transfer =
        money_transfer_fixture(book,
          tenant_id: member.id,
          peers: [%{member_id: member.id, weight: Decimal.new(2)}]
        )

      [peer] = money_transfer.peers

      assert {:ok, updated_transfer} =
               Transfers.update_money_transfer(money_transfer, user, %{
                 peers: [%{id: peer.id, member_id: member.id, weight: Decimal.new(3)}]
               })

      assert [updated_peer] = updated_transfer.peers
      assert updated_peer.id == peer.id
      assert updated_peer.member_id == member.id
      assert updated_peer.weight == Decimal.new(3)
    end

    test "cannot update member_id of existing peer", %{book: book, user: user, member: member} do
      money_transfer =
        money_transfer_fixture(book,
          tenant_id: member.id,
          peers: [%{member_id: member.id}]
        )

      [peer] = money_transfer.peers

      other_user = user_fixture()
      other_member = book_member_fixture(book, other_user)

      assert {:ok, updated_transfer} =
               Transfers.update_money_transfer(
                 money_transfer,
                 user,
                 %{
                   peers: [%{id: peer.id, member_id: other_member.id}]
                 }
               )

      assert [updated_peer] = updated_transfer.peers
      assert updated_peer.id == peer.id
      assert updated_peer.member_id == member.id
    end

    test "deletes peers", %{book: book, user: user, member: member} do
      money_transfer =
        money_transfer_fixture(book,
          tenant_id: member.id,
          peers: [%{member_id: member.id}]
        )

      assert {:ok, updated_transfer} =
               Transfers.update_money_transfer(money_transfer, user, %{
                 peers: []
               })

      assert Enum.empty?(updated_transfer.peers)
    end

    test "cannot create two peers for the same member", %{
      user: user,
      member: member,
      money_transfer: money_transfer
    } do
      assert {:error, changeset} =
               Transfers.update_money_transfer(money_transfer, user, %{
                 peers: [%{member_id: member.id}, %{member_id: member.id}]
               })

      assert errors_on(changeset) == %{
               peers: [%{}, %{member_id: ["member is already a peer of this money transfer"]}]
             }
    end
  end

  describe "delete_money_transfer/1" do
    setup :book_with_member_context
    setup :money_transfer_in_book_context

    test "deletes the money transfer", %{user: user, money_transfer: money_transfer} do
      assert {:ok, deleted_transfer} = Transfers.delete_money_transfer(money_transfer, user)
      assert deleted_transfer.id == money_transfer.id
    end

    test "returns error when user is not a member of the book", %{money_transfer: money_transfer} do
      other_user = user_fixture()

      assert {:error, :unauthorized} = Transfers.delete_money_transfer(money_transfer, other_user)
    end

    test "deleted related peers", %{book: book, user: user, member: member} do
      money_transfer =
        money_transfer_fixture(book,
          tenant_id: member.id,
          peers: [%{member_id: member.id}]
        )

      assert {:ok, _deleted_transfer} = Transfers.delete_money_transfer(money_transfer, user)

      refute Repo.get_by(Peer, transfer_id: money_transfer.id)
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

  # Depends on :book_with_member_context
  defp money_transfer_in_book_context(%{book: book, member: member} = context) do
    Map.put(
      context,
      :money_transfer,
      money_transfer_fixture(book, tenant_id: member.id)
    )
  end
end
