defmodule Anacounts.Accounts.MembersTest do
  use Anacounts.DataCase, async: true

  import Anacounts.AccountsFixtures
  import Anacounts.AuthFixtures

  alias Anacounts.Accounts.Members

  describe "invite_member/2" do
    # XXX In the end, `invite_user` will only send an invite
    # Tests will need to be updated

    setup :setup_user_fixture
    setup :setup_book_fixture

    test "adds a member to the book", %{book: book} do
      remote_user = user_fixture()

      assert {:ok, book_member} = Members.invite_user(book.id, remote_user.email)

      assert book_member.book_id == book.id
      assert book_member.user_id == remote_user.id
      assert book_member.role == :member
    end
  end
end
