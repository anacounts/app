defmodule App.Transfers.PeerTest do
  use App.DataCase, async: true

  import App.BooksFixtures
  import App.Books.MembersFixtures
  import App.TransfersFixtures

  alias App.Transfers.Peer

  setup do
    book = book_fixture()
    member = book_member_fixture(book)
    transfer = money_transfer_fixture(book, tenant_id: member.id)

    %{book: book, member: member, transfer: transfer}
  end

  describe "balance_config_changeset/2" do
    test "changes the `:balance_config_id`", %{member: member, transfer: transfer} do
      peer = %Peer{member_id: member.id, transfer_id: transfer.id}
      changeset = Peer.balance_config_changeset(peer, %{balance_config_id: 1})

      assert changeset.valid?
      assert changeset.changes == %{balance_config_id: 1}
    end

    test "does not change other fields", %{member: member, transfer: transfer} do
      peer = %Peer{member_id: member.id, transfer_id: transfer.id}

      changeset =
        Peer.balance_config_changeset(peer, %{
          weight: 1,
          member_id: 1
        })

      assert changeset.valid?
      assert changeset.changes == %{}
    end
  end
end
