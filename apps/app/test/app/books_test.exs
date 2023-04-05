defmodule App.BooksTest do
  use App.DataCase, async: true

  import App.BalanceFixtures
  import App.AccountsFixtures
  import App.Balance.BalanceConfigsFixtures
  import App.Books.MembersFixtures
  import App.BooksFixtures

  alias App.Balance.TransferParams
  alias App.Books
  alias App.Books.Book
  alias App.Books.Members

  @valid_book_name "A valid book name !"

  @invalid_book_attrs %{name: nil, default_balance_params: %{}}

  describe "get_book!/1" do
    setup do
      %{book: book_fixture()}
    end

    test "returns the book with given id", %{book: book} do
      assert got = Books.get_book!(book.id)
      assert got.id == book.id
    end

    test "raises if book does not exist" do
      assert_raise Ecto.NoResultsError, fn -> Books.get_book!(-1) end
    end
  end

  describe "get_book_of_user/2" do
    setup :book_with_creator_context

    test "returns the book", %{book: book, user: user} do
      user_book = Books.get_book_of_user(book.id, user)
      assert user_book.id == book.id
    end

    test "returns `nil` if the book doesn't belong to the user", %{book: book} do
      other_user = user_fixture()

      assert Books.get_book_of_user(book.id, other_user) == nil
    end

    test "returns `nil` if the book doesn't exist", %{book: book, user: user} do
      assert Books.get_book_of_user(book.id + 10, user) == nil
    end

    test "returns `nil` if the book was deleted", %{book: book, user: user} do
      assert {:ok, _book} = Books.delete_book(book, user)
      refute Books.get_book_of_user(book.id, user)
    end
  end

  describe "get_book_of_user!/2" do
    setup :book_with_creator_context

    test "returns the book", %{book: book, user: user} do
      user_book = Books.get_book_of_user!(book.id, user)
      assert user_book.id == book.id
    end

    test "raises if the book doesn't belong to the user", %{book: book} do
      other_user = user_fixture()

      assert_raise Ecto.NoResultsError, fn ->
        Books.get_book_of_user!(book.id, other_user) == nil
      end
    end

    test "raises if the book doesn't exist", %{book: book, user: user} do
      assert_raise Ecto.NoResultsError, fn ->
        Books.get_book_of_user!(book.id + 10, user) == nil
      end
    end

    test "raises if the book was deleted", %{book: book, user: user} do
      assert {:ok, _book} = Books.delete_book(book, user)

      assert_raise Ecto.NoResultsError, fn ->
        Books.get_book_of_user!(book.id, user)
      end
    end
  end

  describe "list_books_of_user/1" do
    setup :book_with_member_context

    test "returns all user books", %{book: book, user: user} do
      member_of_book = book_fixture()
      _book_membership = book_member_fixture(member_of_book, user_id: user.id)

      _not_member_of_book = book_fixture()

      user_books = Books.list_books_of_user(user)
      assert [book1, book2] = Enum.sort_by(user_books, & &1.id)
      assert book1.id == book.id
      assert book2.id == member_of_book.id
    end
  end

  describe "invitations_suggestions/2" do
    test "returns the users the user is most in books with, ordered" do
      book1 = book_fixture()
      book2 = book_fixture()
      book3 = book_fixture()

      user = user_fixture()
      _member = book_member_fixture(book1, user_id: user.id)
      _member = book_member_fixture(book2, user_id: user.id)

      other_user1 = user_fixture()
      _member = book_member_fixture(book1, user_id: other_user1.id)
      _member = book_member_fixture(book2, user_id: other_user1.id)
      _member = book_member_fixture(book3, user_id: other_user1.id)

      other_user2 = user_fixture()
      _member = book_member_fixture(book2, user_id: other_user2.id)
      _member = book_member_fixture(book3, user_id: other_user2.id)

      other_user3 = user_fixture()
      _member = book_member_fixture(book3, user_id: other_user3.id)

      # pending members aren't suggested and do not interfere
      _member = book_member_fixture(book1)
      _member = book_member_fixture(book1)
      _member = book_member_fixture(book2)

      # `user` is in `book1` with `other_user1`,
      #          and `book2` with `other_user1` and `other_user2`.
      # They are most with `other_user1` (2 books), then `other_user2` (1 book),
      # but never with `other_user3`.
      # The function therefore returns `other_user1` first, then `other_user2`.

      book = book_fixture()
      _member = book_member_fixture(book)

      assert Books.invitations_suggestions(book, user) == [other_user1, other_user2]
    end

    test "does not return user that are already members of the book" do
      book1 = book_fixture()
      book2 = book_fixture()

      user = user_fixture()
      _member = book_member_fixture(book1, user_id: user.id)
      _member = book_member_fixture(book2, user_id: user.id)

      other_user = user_fixture()
      _member = book_member_fixture(book1, user_id: other_user.id)

      # pending members aren't suggested and do not interfere
      _member = book_member_fixture(book1)
      _member = book_member_fixture(book1)
      _member = book_member_fixture(book2)

      suggested_user = user_fixture()
      _member = book_member_fixture(book2, user_id: suggested_user.id)

      assert Books.invitations_suggestions(book1, user) == [suggested_user]
    end
  end

  describe "create_book/2" do
    setup do
      %{user: user_fixture()}
    end

    test "creates a new book and sets the user the creator", %{user: user} do
      user_balance_config_fixture(user)

      {:ok, book} =
        book_attributes(
          name: @valid_book_name,
          default_balance_params: transfer_params_attributes()
        )
        |> Books.create_book(user)

      assert book.name == @valid_book_name

      assert book.default_balance_params ==
               struct!(TransferParams, transfer_params_attributes())

      assert member = Members.get_membership(book.id, user.id)
      assert member.role == :creator
      assert member.balance_config_id == user.balance_config_id
    end

    test "fails when not given a name", %{user: user} do
      {:error, changeset} =
        book_attributes(name: nil)
        |> Books.create_book(user)

      assert errors_on(changeset) == %{name: ["can't be blank"]}
    end

    test "fails when not given balance params", %{user: user} do
      {:error, changeset} =
        book_attributes(default_balance_params: nil)
        |> Books.create_book(user)

      assert errors_on(changeset) == %{default_balance_params: ["can't be blank"]}
    end

    test "fails when given invalid balance params means code", %{user: user} do
      {:error, changeset} =
        book_attributes(
          default_balance_params: %{means_code: :thisaintnovalidoption, params: %{}}
        )
        |> Books.create_book(user)

      assert errors_on(changeset) == %{default_balance_params: ["is invalid"]}
    end

    test "fails when given invalid balance params parameters", %{user: user} do
      {:error, changeset} =
        book_attributes(
          default_balance_params: %{means_code: :divide_equally, params: %{foo: :bar}}
        )
        |> Books.create_book(user)

      assert errors_on(changeset) == %{default_balance_params: ["did not expect any parameter"]}
    end
  end

  describe "update_book/2" do
    setup :book_with_creator_context

    test "updates the book", %{book: book, user: user} do
      assert {:ok, updated} =
               Books.update_book(book, user, %{
                 name: "My awesome new never seen name !",
                 default_balance_params: %{means_code: :weight_by_income}
               })

      assert updated.name == "My awesome new never seen name !"

      assert updated.default_balance_params == %TransferParams{
               means_code: :weight_by_income,
               params: nil
             }
    end

    test "returns error unauthorized if user is not a member of the book", %{book: book} do
      other_user = user_fixture()
      assert {:error, :unauthorized} = Books.update_book(book, other_user, %{name: "foo"})
    end

    test "returns error unauthorized if the user if not allowed to update the book", %{book: book} do
      other_user = user_fixture()
      _other_member = book_member_fixture(book, user_id: other_user.id)

      assert {:error, :unauthorized} = Books.update_book(book, other_user, %{name: "foo"})
    end

    test "returns error changeset with invalid data", %{book: book, user: user} do
      assert {:error, %Ecto.Changeset{}} = Books.update_book(book, user, @invalid_book_attrs)

      assert got = Books.get_book!(book.id)
      assert got.id == book.id
    end
  end

  describe "delete_book/2" do
    setup :book_with_creator_context

    test "deletes the book", %{book: book, user: user} do
      assert {:ok, deleted} = Books.delete_book(book, user)
      assert deleted.id == book.id

      assert deleted_book = Repo.get(Book, book.id)
      assert deleted_book.deleted_at
    end

    test "does not delete the book if the user is not a member of the book", %{book: book} do
      assert {:error, :unauthorized} = Books.delete_book(book, user_fixture())
    end

    test "does not delete the book if the user is not allowed to", %{book: book} do
      other_user = user_fixture()
      _other_member = book_member_fixture(book, user_id: other_user.id)

      assert {:error, :unauthorized} = Books.delete_book(book, other_user)
    end
  end

  describe "change_book/1" do
    setup do
      %{book: book_fixture()}
    end

    test "returns a book changeset", %{book: book} do
      assert %Ecto.Changeset{} = Books.change_book(book)
    end
  end

  defp book_with_creator_context(_context), do: book_with_member_role(:creator)

  defp book_with_member_context(_context), do: book_with_member_role(:member)

  defp book_with_member_role(role) do
    book = book_fixture()
    user = user_fixture()
    member = book_member_fixture(book, user_id: user.id, role: role)

    %{
      book: book,
      user: user,
      member: member
    }
  end
end
