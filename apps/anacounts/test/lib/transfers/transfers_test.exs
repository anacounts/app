defmodule Anacounts.TransfersTest do
  use Anacounts.DataCase, async: true

  import Anacounts.AccountsFixtures
  import Anacounts.AuthFixtures
  import Anacounts.TransfersFixtures

  alias Anacounts.Transfers

  describe "find_transfers_in_book/1" do
    setup :setup_user_fixture
    setup :setup_book_fixture

    test "find all transfers in book", %{book: book, user: user} do
      transfer = money_transfer_fixture(book, user)

      assert [found_transfer] = Transfers.find_transfers_in_book(book.id)
      assert found_transfer.id == transfer.id
    end
  end

  describe "create_transfer/3" do
    setup :setup_user_fixture
    setup :setup_book_fixture

    test "creates a money transfer", %{book: book, user: user} do
      assert {:ok, transfer} =
               Transfers.create_transfer(
                 book.id,
                 user.id,
                 valid_money_transfer_attributes()
               )

      assert transfer.amount == valid_money_transfer_amount()
      assert transfer.type == valid_money_transfer_type()
      assert transfer.date == valid_money_transfer_date()
      assert Enum.empty?(transfer.peers)
    end

    test "creates peers along the way", %{book: book, user: user} do
      user2 = user_fixture()

      assert {:ok, transfer} =
               Transfers.create_transfer(
                 book.id,
                 user.id,
                 valid_money_transfer_attributes(%{
                   peers: [%{user_id: user.id}, %{user_id: user2.id, weight: Decimal.new(3)}]
                 })
               )

      [peer1, peer2] = Enum.sort_by(transfer.peers, & &1.weight)

      assert peer1.user_id == user.id
      assert peer2.user_id == user2.id
      assert peer2.weight == Decimal.new(3)
    end

    test "cannot create two peers for the same user", %{book: book, user: user} do
      assert {:error, changeset} =
               Transfers.create_transfer(
                 book.id,
                 user.id,
                 valid_money_transfer_attributes(%{
                   peers: [%{user_id: user.id}, %{user_id: user.id}]
                 })
               )

      assert errors_on(changeset) == %{
               peers: [%{}, %{user_id: ["user is already a peer of this money transfer"]}]
             }
    end

    test "fails with invalid book_id", %{user: user} do
      assert {:error, changeset} =
               Transfers.create_transfer(0, user.id, valid_money_transfer_attributes())

      assert errors_on(changeset) == %{book_id: ["does not exist"]}
    end

    test "fails with invalid user_id", %{book: book} do
      assert {:error, changeset} =
               Transfers.create_transfer(book.id, 0, valid_money_transfer_attributes())

      assert errors_on(changeset) == %{holder_id: ["does not exist"]}
    end
  end

  describe "update_transfer/2" do
    setup :setup_user_fixture
    setup :setup_book_fixture
    setup :setup_money_transfer_fixture

    test "updates the money transfer", %{money_transfer: money_transfer} do
      other_user = user_fixture()

      assert {:ok, updated} =
               Transfers.update_transfer(money_transfer, %{
                 amount: Money.new(299, :EUR),
                 type: :income,
                 date: ~U[2020-06-29T17:31:28Z],
                 peers: [%{user_id: other_user.id}]
               })

      assert updated.amount == Money.new(299, :EUR)
      assert updated.type == :income
      assert updated.date == ~U[2020-06-29T17:31:28Z]
      assert [peer] = updated.peers
      assert peer.user_id == other_user.id
    end

    test "does not update book or holder", %{
      book: book,
      user: user,
      money_transfer: money_transfer
    } do
      other_user = user_fixture()
      other_book = book_fixture(user)

      assert {:ok, updated} =
               Transfers.update_transfer(money_transfer, %{
                 holder_id: other_user.id,
                 book_id: other_book.id
               })

      assert updated.holder_id == user.id
      assert updated.book_id == book.id
    end

    test "updates existing peers", %{book: book, user: user} do
      money_transfer =
        money_transfer_fixture(book, user, %{
          peers: [%{user_id: user.id, weight: Decimal.new(2)}]
        })

      [peer] = money_transfer.peers

      assert {:ok, updated_transfer} =
               Transfers.update_transfer(money_transfer, %{
                 peers: [%{id: peer.id, user_id: user.id, weight: Decimal.new(3)}]
               })

      assert [updated_peer] = updated_transfer.peers
      assert updated_peer.id == peer.id
      assert updated_peer.user_id == user.id
      assert updated_peer.weight == Decimal.new(3)
    end

    test "cannot update user_id of existing peer", %{book: book, user: user} do
      money_transfer =
        money_transfer_fixture(book, user, %{
          peers: [%{user_id: user.id}]
        })

      [peer] = money_transfer.peers

      other_user = user_fixture()

      assert {:ok, updated_transfer} =
               Transfers.update_transfer(money_transfer, %{
                 peers: [%{id: peer.id, user_id: other_user.id}]
               })

      assert [updated_peer] = updated_transfer.peers
      assert updated_peer.id == peer.id
      assert updated_peer.user_id == user.id
    end

    test "deletes peers", %{book: book, user: user} do
      money_transfer =
        money_transfer_fixture(book, user, %{
          peers: [%{user_id: user.id}]
        })

      assert {:ok, updated_transfer} =
               Transfers.update_transfer(money_transfer, %{
                 peers: []
               })

      assert Enum.empty?(updated_transfer.peers)
    end

    test "cannot create two peers for the same user", %{
      user: user,
      money_transfer: money_transfer
    } do
      assert {:error, changeset} =
               Transfers.update_transfer(money_transfer, %{
                 peers: [%{user_id: user.id}, %{user_id: user.id}]
               })

      assert errors_on(changeset) == %{
               peers: [%{}, %{user_id: ["user is already a peer of this money transfer"]}]
             }
    end
  end
end
