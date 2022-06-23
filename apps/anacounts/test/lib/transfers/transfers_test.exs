defmodule Anacounts.TransfersTest do
  use Anacounts.DataCase, async: true

  import Anacounts.AccountsFixtures
  import Anacounts.AuthFixtures
  import Anacounts.TransfersFixtures

  alias Anacounts.Transfers

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
end
