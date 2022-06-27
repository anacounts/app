defmodule Anacounts.AccountsTest do
  use Anacounts.DataCase, async: true

  import Anacounts.AccountsFixtures
  import Anacounts.AuthFixtures

  alias Anacounts.Accounts

  describe "get_book_of_user/2" do
    setup :setup_user_fixture
    setup :setup_book_fixture

    test "returns the book", %{book: book, user: user} do
      user_book = Accounts.get_book_of_user(book.id, user)
      assert user_book.id == book.id
    end

    test "returns `nil` if the book doesn't belong to the user", %{book: book} do
      other_user = user_fixture()

      assert Accounts.get_book_of_user(book.id, other_user) == nil
    end

    test "returns `nil` if the book doesn't exist", %{book: book, user: user} do
      assert Accounts.get_book_of_user(book.id + 10, user) == nil
    end

    test "returns `nil` if the book was deleted", %{book: book, user: user} do
      assert {:ok, _book} = Accounts.delete_book(book)
      refute Accounts.get_book_of_user(book.id, user)
    end
  end

  describe "find_user_books/1" do
    setup :setup_user_fixture
    setup :setup_book_fixture

    test "returns all user books", %{book: book, user: user} do
      another_user = user_fixture()
      another_book = book_fixture(another_user, %{name: "Some other book from someone else"})
      _book_member = book_member_fixture(another_book, user)

      user_books = Accounts.find_user_books(user)
      assert [book1, book2] = Enum.sort_by(user_books, & &1.id)
      assert book1.id == book.id
      assert book2.id == another_book.id
    end
  end

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

    test "deletes the book", %{book: book} do
      assert {:ok, deleted} = Accounts.delete_book(book)
      assert deleted.id == book.id

      assert deleted_book = Repo.get(Accounts.Book, book.id)
      assert deleted_book.deleted_at
    end
  end
end
