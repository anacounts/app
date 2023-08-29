defmodule App.Books.MembersTest do
  use App.DataCase, async: true

  import App.AccountsFixtures
  import App.BooksFixtures
  import App.Books.MembersFixtures

  alias App.Books.Members

  describe "list_members_of_book/1" do
    test "lists all members of a book" do
      book = book_fixture()
      confirmed_member = book_member_fixture(book, user_id: user_fixture().id)
      pending_member = book_member_fixture(book, user_id: nil)
      _other_member = book_member_fixture(book_fixture())

      assert book
             |> Members.list_members_of_book()
             |> Enum.map(& &1.id)
             |> Enum.sort() == [confirmed_member.id, pending_member.id]
    end
  end

  describe "get_member_of_book!/2" do
    setup :book_with_creator_context

    test "returns the member of a book with given id", %{book: book} do
      other_user = user_fixture()
      book_member = book_member_fixture(book, user_id: other_user.id)

      assert result = Members.get_member_of_book!(book_member.id, book)
      assert result.id == book_member.id
      assert result.book_id == book_member.book_id
      assert result.user_id == book_member.user_id
    end

    test "raises if the member does not belong to the book", %{book: book} do
      other_book = book_fixture()
      book_member = book_member_fixture(other_book)

      assert_raise Ecto.NoResultsError, fn ->
        Members.get_member_of_book!(book_member.id, book)
      end
    end

    test "raises if the member does not exist" do
      assert_raise Ecto.NoResultsError, fn ->
        Members.get_member_of_book!(-1, book_fixture())
      end
    end
  end

  describe "create_book_member/2" do
    setup do
      %{book: book_fixture()}
    end

    test "create a new book member", %{book: book} do
      assert {:ok, _book_member} = Members.create_book_member(book, %{nickname: "Member"})
    end

    test "cannot set the user_id", %{book: book} do
      assert {:ok, book_member} =
               Members.create_book_member(book, %{nickname: "Member", user_id: 1})

      assert book_member.user_id == nil
    end

    test "returns an error if given invalid attributes", %{book: book} do
      assert {:error, changeset} =
               Members.create_book_member(book, book_member_attributes(nickname: ""))

      assert errors_on(changeset) == %{nickname: ["can't be blank"]}
    end
  end

  describe "update_book_member/2" do
    setup do
      book = book_fixture()
      book_member = book_member_fixture(book)

      %{book: book, book_member: book_member}
    end

    test "updates the book member", %{book_member: book_member} do
      assert {:ok, book_member} =
               Members.update_book_member(book_member, %{nickname: "New Nickname"})

      assert book_member.nickname == "New Nickname"
    end

    test "fails if given invalid values", %{book_member: book_member} do
      assert {:error, changeset} =
               Members.update_book_member(book_member, %{nickname: ""})

      assert errors_on(changeset) == %{nickname: ["can't be blank"]}
    end

    test "cannot set the user_id", %{book_member: book_member} do
      assert {:ok, book_member} = Members.update_book_member(book_member, %{user_id: 1})
      assert book_member.user_id == nil
    end
  end

  describe "change_book_member/2" do
    setup do
      book = book_fixture()
      book_member = book_member_fixture(book)

      %{book: book, book_member: book_member}
    end

    test "returns a changeset for the given book member", %{book_member: book_member} do
      assert changeset = Members.change_book_member(book_member)
      assert changeset.valid?
      assert changeset.params == %{}
    end

    test "validates the user attributes", %{book_member: book_member} do
      assert changeset = Members.change_book_member(book_member, %{nickname: ""})
      assert errors_on(changeset) == %{nickname: ["can't be blank"]}
    end

    test "cannot set the user_id", %{book_member: book_member} do
      assert changeset = Members.change_book_member(book_member, %{user_id: 1})
      assert changeset.valid?
      refute Ecto.Changeset.changed?(changeset, :user_id)
    end
  end

  defp book_with_creator_context(_context) do
    book = book_fixture()
    user = user_fixture()
    member = book_member_fixture(book, user_id: user.id, role: :creator)

    %{
      book: book,
      user: user,
      member: member
    }
  end
end
