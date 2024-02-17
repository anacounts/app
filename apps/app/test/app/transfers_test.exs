defmodule App.TransfersTest do
  use App.DataCase, async: true

  import App.AccountsFixtures
  import App.Balance.BalanceConfigsFixtures
  import App.BalanceFixtures
  import App.Books.MembersFixtures
  import App.BooksFixtures
  import App.TransfersFixtures

  alias App.Repo

  alias App.Balance.TransferParams
  alias App.Books.Book
  alias App.Transfers
  alias App.Transfers.Peer

  describe "list_transfers_of_book/2" do
    setup :book_with_member_context

    test "lists all transfers in book", %{book: book, member: member} do
      transfer = money_transfer_fixture(book, tenant_id: member.id)

      assert [found_transfer] = Transfers.list_transfers_of_book(book)
      assert found_transfer.id == transfer.id
    end

    test "sorts by most recent", %{book: book, member: member} do
      transfer1 = money_transfer_fixture(book, date: ~D[2020-06-29], tenant_id: member.id)
      transfer2 = money_transfer_fixture(book, date: ~D[2020-06-30], tenant_id: member.id)

      assert Transfers.list_transfers_of_book(book, filters: %{sort_by: :most_recent})
             |> Enum.map(& &1.id) == [transfer2.id, transfer1.id]
    end

    test "sorts by oldest", %{book: book, member: member} do
      transfer1 = money_transfer_fixture(book, date: ~D[2020-06-29], tenant_id: member.id)
      transfer2 = money_transfer_fixture(book, date: ~D[2020-06-30], tenant_id: member.id)

      assert Transfers.list_transfers_of_book(book, filters: %{sort_by: :oldest})
             |> Enum.map(& &1.id) == [transfer1.id, transfer2.id]
    end

    test "sorts by last created", %{book: book, member: member} do
      transfer1 =
        money_transfer_fixture(book, inserted_at: ~N[2020-06-29 12:00:00], tenant_id: member.id)

      transfer2 =
        money_transfer_fixture(book, inserted_at: ~N[2020-06-30 12:00:00], tenant_id: member.id)

      assert Transfers.list_transfers_of_book(book, filters: %{sort_by: :last_created})
             |> Enum.map(& &1.id) == [transfer2.id, transfer1.id]
    end

    test "sorts by first created", %{book: book, member: member} do
      transfer1 =
        money_transfer_fixture(book, inserted_at: ~N[2020-06-29 12:00:00], tenant_id: member.id)

      transfer2 =
        money_transfer_fixture(book, inserted_at: ~N[2020-06-30 12:00:00], tenant_id: member.id)

      assert Transfers.list_transfers_of_book(book, filters: %{sort_by: :first_created})
             |> Enum.map(& &1.id) == [transfer1.id, transfer2.id]
    end

    test "filters by tenanted by anyone", %{book: book} do
      member1 = book_member_fixture(book)
      transfer1 = money_transfer_fixture(book, tenant_id: member1.id)

      member2 = book_member_fixture(book)
      transfer2 = money_transfer_fixture(book, tenant_id: member2.id)

      assert Transfers.list_transfers_of_book(book, filters: %{tenanted_by: :anyone})
             |> Enum.map(& &1.id)
             |> Enum.sort() == [transfer1.id, transfer2.id]
    end

    test "filters by tenanted by member", %{book: book} do
      member1 = book_member_fixture(book)
      transfer1 = money_transfer_fixture(book, tenant_id: member1.id)

      member2 = book_member_fixture(book)
      _transfer2 = money_transfer_fixture(book, tenant_id: member2.id)

      assert Transfers.list_transfers_of_book(book, filters: %{tenanted_by: member1.id})
             |> Enum.map(& &1.id) == [transfer1.id]
    end

    test "filters by tenanted by not member", %{book: book} do
      member1 = book_member_fixture(book)
      _transfer1 = money_transfer_fixture(book, tenant_id: member1.id)

      member2 = book_member_fixture(book)
      transfer2 = money_transfer_fixture(book, tenant_id: member2.id)

      assert Transfers.list_transfers_of_book(book, filters: %{tenanted_by: {:not, member1.id}})
             |> Enum.map(& &1.id) == [transfer2.id]
    end
  end

  describe "list_transfers_of_members/1" do
    setup do
      %{book: book_fixture()}
    end

    test "lists all transfers linked to members", %{book: book} do
      member1 = book_member_fixture(book)
      member2 = book_member_fixture(book)

      transfer1 =
        deprecated_money_transfer_fixture(book,
          tenant_id: member1.id,
          peers: [%{member_id: member2.id}]
        )

      transfer2 =
        deprecated_money_transfer_fixture(book,
          tenant_id: member2.id,
          peers: [%{member_id: member1.id}, %{member_id: member2.id}]
        )

      assert Transfers.list_transfers_of_members([member1, member2])
             |> Enum.map(& &1.id)
             |> Enum.sort() == [transfer1.id, transfer2.id]
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
                   amount: Money.new!(:EUR, 1799),
                   type: :payment,
                   date: ~D[2022-06-23]
                 )
               )

      assert transfer.label == "A label"
      assert transfer.amount == Money.new!(:EUR, 1799)
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
      member_balance_config = member_balance_config_fixture(member)

      other_user = user_fixture()
      other_member = book_member_fixture(book, user_id: other_user.id)

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
      assert peer1.balance_config_id == member_balance_config.id
      assert peer2.member_id == other_member.id
      refute peer2.balance_config_id
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

    test "updates the money transfer", %{book: book, money_transfer: money_transfer} do
      other_user = user_fixture()
      other_member = book_member_fixture(book, user_id: other_user.id)

      assert {:ok, updated} =
               Transfers.update_money_transfer(money_transfer, %{
                 label: "my very own label !",
                 amount: Money.new!(:EUR, 299),
                 type: :income,
                 date: ~D[2020-06-29],
                 balance_params: transfer_params_attributes(),
                 peers: [%{member_id: other_member.id}]
               })

      assert updated.label == "my very own label !"
      assert updated.amount == Money.new!(:EUR, 299)
      assert updated.type == :income
      assert updated.date == ~D[2020-06-29]

      assert updated.balance_params ==
               struct!(TransferParams, transfer_params_attributes())

      assert [peer] = updated.peers
      assert peer.member_id == other_member.id
    end

    test "does not update book", %{book: book, money_transfer: money_transfer} do
      other_book = book_fixture()

      assert {:ok, updated} =
               Transfers.update_money_transfer(money_transfer, %{
                 book_id: other_book.id
               })

      assert updated.book_id == book.id
    end

    test "updates existing peers", %{book: book, member: member} do
      money_transfer =
        deprecated_money_transfer_fixture(book,
          tenant_id: member.id,
          peers: [%{member_id: member.id, weight: Decimal.new(2)}]
        )

      [peer] = money_transfer.peers

      assert {:ok, updated_transfer} =
               Transfers.update_money_transfer(money_transfer, %{
                 peers: [%{id: peer.id, member_id: member.id, weight: Decimal.new(3)}]
               })

      assert [updated_peer] = updated_transfer.peers
      assert updated_peer.id == peer.id
      assert updated_peer.member_id == member.id
      assert updated_peer.weight == Decimal.new(3)
    end

    test "cannot update member_id of existing peer", %{book: book, member: member} do
      money_transfer =
        deprecated_money_transfer_fixture(book,
          tenant_id: member.id,
          peers: [%{member_id: member.id}]
        )

      [peer] = money_transfer.peers

      other_user = user_fixture()
      other_member = book_member_fixture(book, user_id: other_user.id)

      assert {:ok, updated_transfer} =
               Transfers.update_money_transfer(money_transfer, %{
                 peers: [%{id: peer.id, member_id: other_member.id}]
               })

      assert [updated_peer] = updated_transfer.peers
      assert updated_peer.id == peer.id
      assert updated_peer.member_id == member.id
    end

    test "deletes peers", %{book: book, member: member} do
      money_transfer =
        deprecated_money_transfer_fixture(book,
          tenant_id: member.id,
          peers: [%{member_id: member.id}]
        )

      assert {:ok, updated_transfer} =
               Transfers.update_money_transfer(money_transfer, %{
                 peers: []
               })

      assert Enum.empty?(updated_transfer.peers)
    end

    test "cannot create two peers for the same member", %{
      member: member,
      money_transfer: money_transfer
    } do
      assert {:error, changeset} =
               Transfers.update_money_transfer(money_transfer, %{
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

    test "deletes the money transfer", %{money_transfer: money_transfer} do
      assert {:ok, deleted_transfer} = Transfers.delete_money_transfer(money_transfer)
      assert deleted_transfer.id == money_transfer.id
    end

    test "deleted related peers", %{book: book, member: member} do
      money_transfer =
        deprecated_money_transfer_fixture(book,
          tenant_id: member.id,
          peers: [%{member_id: member.id}]
        )

      assert {:ok, _deleted_transfer} = Transfers.delete_money_transfer(money_transfer)

      refute Repo.get_by(Peer, transfer_id: money_transfer.id)
    end
  end

  defp book_with_member_context(_context) do
    book = book_fixture()
    user = user_fixture()
    member = book_member_fixture(book, user_id: user.id)

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
