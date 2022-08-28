defmodule App.AccountsTest do
  use App.DataCase, async: true

  import App.AccountsFixtures
  import App.AuthFixtures
  import App.BooksFixtures

  alias App.Accounts

  ## Members

  describe "find_book_members/1" do
    setup :setup_user_fixture
    setup :setup_book_fixture

    test "returns all members of a book", %{book: book, user: user} do
      other_user = user_fixture()
      _other_member = book_member_fixture(book, other_user)

      book_members = Accounts.find_book_members(book)
      assert [member1, member2] = Enum.sort_by(book_members, & &1.id)
      assert member1.user_id == user.id
      assert member2.user_id == other_user.id
    end
  end

  # TODO Add tests for get_membership/2
end
