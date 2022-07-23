defmodule App.TransfersTest do
  use App.DataCase, async: true

  import App.AccountsFixtures
  import App.Accounts.BalanceFixtures
  import App.AuthFixtures
  import App.TransfersFixtures

  alias App.Repo

  alias App.Transfers

  describe "find_transfers_in_book/1" do
    setup :setup_user_fixture
    setup :setup_book_fixture
    setup :setup_book_member_fixture

    test "find all transfers in book", %{book: book, book_member: book_member} do
      transfer = money_transfer_fixture(book_id: book.id, tenant_id: book_member.id)

      assert [found_transfer] = Transfers.find_transfers_in_book(book.id)
      assert found_transfer.id == transfer.id
    end
  end

  describe "create_money_transfer/1" do
    setup :setup_user_fixture
    setup :setup_book_fixture
    setup :setup_book_member_fixture

    test "creates a money transfer", %{book: book, book_member: book_member} do
      assert {:ok, transfer} =
               Transfers.create_money_transfer(
                 valid_money_transfer_attributes(book_id: book.id, tenant_id: book_member.id)
               )

      assert transfer.label == valid_money_transfer_label()
      assert transfer.amount == valid_money_transfer_amount()
      assert transfer.type == valid_money_transfer_type()
      assert transfer.date == valid_money_transfer_date()
      assert transfer.balance_params == nil
      assert Enum.empty?(transfer.peers)
    end

    test "sets balance params", %{book: book, book_member: book_member} do
      assert {:ok, transfer} =
               Transfers.create_money_transfer(
                 valid_money_transfer_attributes(
                   book_id: book.id,
                   tenant_id: book_member.id,
                   balance_params: valid_balance_transfer_params_attrs()
                 )
               )

      assert transfer.balance_params == valid_balance_transfer_params_attrs()
    end

    test "creates peers along the way", %{book: book, book_member: book_member} do
      other_user = user_fixture()
      other_member = book_member_fixture(book, other_user)

      assert {:ok, transfer} =
               Transfers.create_money_transfer(
                 valid_money_transfer_attributes(
                   book_id: book.id,
                   tenant_id: book_member.id,
                   peers: [
                     %{member_id: book_member.id},
                     %{member_id: other_member.id, weight: Decimal.new(3)}
                   ]
                 )
               )

      [peer1, peer2] = Enum.sort_by(transfer.peers, & &1.weight)

      assert peer1.member_id == book_member.id
      assert peer2.member_id == other_member.id
      assert peer2.weight == Decimal.new(3)
    end

    test "cannot create two peers for the same user", %{book: book, book_member: book_member} do
      assert {:error, changeset} =
               Transfers.create_money_transfer(
                 valid_money_transfer_attributes(
                   book_id: book.id,
                   tenant_id: book_member.id,
                   peers: [%{member_id: book_member.id}, %{member_id: book_member.id}]
                 )
               )

      assert errors_on(changeset) == %{
               peers: [%{}, %{member_id: ["member is already a peer of this money transfer"]}]
             }
    end

    test "fails with invalid book_id", %{book_member: book_member} do
      assert {:error, changeset} =
               Transfers.create_money_transfer(
                 valid_money_transfer_attributes(book_id: 0, tenant_id: book_member.id)
               )

      assert errors_on(changeset) == %{book_id: ["does not exist"]}
    end

    test "fails with missing tenant_id", %{book: book} do
      assert {:error, changeset} =
               Transfers.create_money_transfer(valid_money_transfer_attributes(book_id: book.id))

      assert errors_on(changeset) == %{tenant_id: ["can't be blank"]}
    end

    test "fails with invalid tenant_id", %{book: book} do
      assert {:error, changeset} =
               Transfers.create_money_transfer(
                 valid_money_transfer_attributes(book_id: book.id, tenant_id: 0)
               )

      assert errors_on(changeset) == %{tenant_id: ["does not exist"]}
    end
  end

  describe "update_money_transfer/2" do
    setup :setup_user_fixture
    setup :setup_book_fixture
    setup :setup_book_member_fixture
    setup :setup_money_transfer_fixture

    test "updates the money transfer", %{book: book, money_transfer: money_transfer} do
      other_user = user_fixture()
      other_member = book_member_fixture(book, other_user)

      assert {:ok, updated} =
               Transfers.update_money_transfer(money_transfer, %{
                 label: "my very own label !",
                 amount: Money.new(299, :EUR),
                 type: :income,
                 date: ~D[2020-06-29],
                 balance_params: valid_balance_transfer_params_attrs(),
                 peers: [%{member_id: other_member.id}]
               })

      assert updated.label == "my very own label !"
      assert updated.amount == Money.new(299, :EUR)
      assert updated.type == :income
      assert updated.date == ~D[2020-06-29]
      assert updated.balance_params == valid_balance_transfer_params_attrs()
      assert [peer] = updated.peers
      assert peer.member_id == other_member.id
    end

    test "does not update book", %{book: book, user: user, money_transfer: money_transfer} do
      other_book = book_fixture(user)

      assert {:ok, updated} =
               Transfers.update_money_transfer(money_transfer, %{
                 book_id: other_book.id
               })

      assert updated.book_id == book.id
    end

    test "updates existing peers", %{book: book, book_member: book_member} do
      money_transfer =
        money_transfer_fixture(
          book_id: book.id,
          tenant_id: book_member.id,
          peers: [%{member_id: book_member.id, weight: Decimal.new(2)}]
        )

      [peer] = money_transfer.peers

      assert {:ok, updated_transfer} =
               Transfers.update_money_transfer(money_transfer, %{
                 peers: [%{id: peer.id, member_id: book_member.id, weight: Decimal.new(3)}]
               })

      assert [updated_peer] = updated_transfer.peers
      assert updated_peer.id == peer.id
      assert updated_peer.member_id == book_member.id
      assert updated_peer.weight == Decimal.new(3)
    end

    test "cannot update member_id of existing peer", %{book: book, book_member: book_member} do
      money_transfer =
        money_transfer_fixture(
          book_id: book.id,
          tenant_id: book_member.id,
          peers: [%{member_id: book_member.id}]
        )

      [peer] = money_transfer.peers

      other_user = user_fixture()
      other_member = book_member_fixture(book, other_user)

      assert {:ok, updated_transfer} =
               Transfers.update_money_transfer(money_transfer, %{
                 peers: [%{id: peer.id, member_id: other_member.id}]
               })

      assert [updated_peer] = updated_transfer.peers
      assert updated_peer.id == peer.id
      assert updated_peer.member_id == book_member.id
    end

    test "deletes peers", %{book: book, book_member: book_member} do
      money_transfer =
        money_transfer_fixture(
          book_id: book.id,
          tenant_id: book_member.id,
          peers: [%{member_id: book_member.id}]
        )

      assert {:ok, updated_transfer} =
               Transfers.update_money_transfer(money_transfer, %{
                 peers: []
               })

      assert Enum.empty?(updated_transfer.peers)
    end

    test "cannot create two peers for the same member", %{
      book_member: book_member,
      money_transfer: money_transfer
    } do
      assert {:error, changeset} =
               Transfers.update_money_transfer(money_transfer, %{
                 peers: [%{member_id: book_member.id}, %{member_id: book_member.id}]
               })

      assert errors_on(changeset) == %{
               peers: [%{}, %{member_id: ["member is already a peer of this money transfer"]}]
             }
    end
  end

  describe "delete_money_transfer/1" do
    setup :setup_user_fixture
    setup :setup_book_fixture
    setup :setup_book_member_fixture
    setup :setup_money_transfer_fixture

    test "deletes the money transfer", %{money_transfer: money_transfer} do
      assert {:ok, deleted_transfer} = Transfers.delete_money_transfer(money_transfer)
      assert deleted_transfer.id == money_transfer.id
    end

    test "deleted related peers", %{book: book, book_member: book_member} do
      money_transfer =
        money_transfer_fixture(
          book_id: book.id,
          tenant_id: book_member.id,
          peers: [%{member_id: book_member.id}]
        )

      assert {:ok, _deleted_transfer} = Transfers.delete_money_transfer(money_transfer)

      refute Repo.get_by(Transfers.Peer, transfer_id: money_transfer.id)
    end
  end
end
