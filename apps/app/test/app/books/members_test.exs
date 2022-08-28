defmodule App.Books.MembersTest do
  use App.DataCase

  import App.AuthFixtures
  import App.BooksFixtures
  import App.Books.MembersFixtures

  alias App.Books.Members

  describe "get_book_member!/1" do
    setup [:setup_user_fixture, :setup_book_fixture]

    test "returns the book_member with given id", %{book: book} do
      other_user = user_fixture()
      book_member = book_member_fixture(book, other_user)
      assert Members.get_book_member!(book_member.id) == book_member
    end

    test "raises if the book_member does not exist" do
      assert_raise Ecto.NoResultsError, fn ->
        Members.get_book_member!(-1)
      end
    end
  end
end
