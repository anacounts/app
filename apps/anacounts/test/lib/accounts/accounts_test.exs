defmodule Anacounts.AccountsTest do
  use Anacounts.DataCase, async: true

  import Anacounts.AccountsFixtures
  import Anacounts.AuthFixtures

  alias Anacounts.Accounts

  describe "get_book/2" do
    setup :setup_user_fixture
    setup :setup_book_fixture

    test "returns the book", %{book: book, user: user} do
      user_book = Accounts.get_book(book.id, user)
      assert user_book.id == book.id
    end

    test "returns `nil` if the book doesn't belong to the user", %{book: book} do
      other_user = user_fixture()

      assert Accounts.get_book(book.id, other_user) == nil
    end

    test "returns `nil` if the book doesn't exist", %{book: book, user: user} do
      assert Accounts.get_book(book.id + 10, user) == nil
    end

    # XXX Add a test when books can be deleted
    # test "returns `nil` if the book was deleted" do
  end

  describe "find_user_books/1" do
    setup :setup_user_fixture
    setup :setup_book_fixture

    test "returns all user books", %{book: book, user: user} do
      # XXX Add a test when a user can become a "member" of another user's book
      # another_user = user_fixture()
      # another_book = book_fixture(another_user, %{ name: "Some other book from someone else })
      # {:ok, book_member} = Accounts.add_book_member(another_book, user)

      user_books = Accounts.find_user_books(user)
      assert length(user_books) == 1
      assert hd(user_books).id == book.id
    end
  end

  describe "find_book_members/1" do
    setup :setup_user_fixture
    setup :setup_book_fixture

    test "returns all members of a book", %{book: book, user: user} do
      # XXX Add a test when a user can become a "member" of another user's book
      # another_user = user_fixture()
      # {:ok, _book_member} = Accounts.add_book_member(book, another_user)

      book_members = Accounts.find_book_members(book)
      assert length(book_members) == 1
      assert hd(book_members).user_id == user.id
    end
  end

  describe "create_book/2" do
    setup :setup_user_fixture

    test "creates a new book belonging to the user", %{user: user} do
      {:ok, book} = Accounts.create_book(user, valid_book_attributes())

      assert hd(book.members).user_id == user.id
    end

    test "fails when giving invalid parameters", %{user: user} do
      {:error, changeset} =
        Accounts.create_book(user, %{
          name: nil
        })

      assert "can't be blank" in errors_on(changeset).name
    end
  end

  describe "delete_book/2" do
    setup :setup_user_fixture
    setup :setup_book_fixture

    test "deletes the book", %{user: user, book: book} do
      assert {:ok, deleted} = Accounts.delete_book(book)
      assert deleted.id == book.id

      assert deleted_book = Repo.get(Accounts.Book, book.id)
      assert deleted_book.deleted_at
    end
  end
end
