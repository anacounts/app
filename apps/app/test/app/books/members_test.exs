defmodule App.Books.MembersTest do
  use App.DataCase, async: true

  import App.AuthFixtures
  import App.BooksFixtures
  import App.Books.MembersFixtures

  alias App.Books.Members

  describe "invite_member/2" do
    # XXX In the end, `invite_new_member` will only send an invite
    # Tests will need to be updated

    setup :setup_user_fixture
    setup :setup_book_fixture

    test "adds a member to the book", %{book: book, user: user} do
      invited_user = user_fixture()

      assert {:ok, book_member} = Members.invite_new_member(book.id, user, invited_user.email)

      assert book_member.book_id == book.id
      assert book_member.user_id == invited_user.id
      assert book_member.role == :member
    end

    test "returns an error if the user is not allowed a member of the book", %{book: book} do
      other_user = user_fixture()
      invited_user = user_fixture()

      assert {:error, :unauthorized} =
               Members.invite_new_member(book.id, other_user, invited_user.email)
    end

    test "returns an error if the user is not allowed to invite new members", %{book: book} do
      other_user = user_fixture()
      _other_member = book_member_fixture(book, other_user)

      invited_user = user_fixture()

      assert {:error, :unauthorized} =
               Members.invite_new_member(book.id, other_user, invited_user.email)
    end

    test "fails if the user is already member", %{book: book, user: user} do
      invited_user = user_fixture()

      # Create the first membership
      assert {:ok, _book_member} = Members.invite_new_member(book.id, user, invited_user.email)

      assert {:error, changeset} = Members.invite_new_member(book.id, user, invited_user.email)
      assert errors_on(changeset) == %{user_id: ["user is already a member of this book"]}
    end
  end

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
