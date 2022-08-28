defmodule App.Accounts.MembersTest do
  use App.DataCase, async: true

  import App.AuthFixtures
  import App.BooksFixtures

  alias App.Accounts.Members

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

    test "fails if the user is already member", %{book: book} do
      remote_user = user_fixture()

      # Create the first membership
      assert {:ok, _book_member} = Members.invite_user(book.id, remote_user.email)

      assert {:error, changeset} = Members.invite_user(book.id, remote_user.email)
      assert errors_on(changeset) == %{user_id: ["user is already a member of this book"]}
    end
  end
end
