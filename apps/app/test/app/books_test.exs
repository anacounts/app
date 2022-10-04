defmodule App.BooksTest do
  use App.DataCase, async: true

  import App.BalanceFixtures
  import App.AuthFixtures
  import App.BooksFixtures
  import App.Books.MembersFixtures

  alias App.Balance.TransferParams
  alias App.Books
  alias App.Books.Book

  @invalid_book_attrs %{name: nil, default_balance_params: %{}}

  describe "get_book_of_user/2" do
    setup :setup_user_fixture
    setup :setup_book_fixture

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

  describe "get_book!/1" do
    setup :setup_user_fixture
    setup :setup_book_fixture

    # TODO don't automatically insert members when creating book fixture
    # test "returns the book with given id", %{book: book} do
    #   assert Books.get_book!(book.id) == book
    # end

    test "raises if book does not exist" do
      assert_raise Ecto.NoResultsError, fn -> Books.get_book!(-1) end
    end
  end

  describe "find_user_books/1" do
    setup :setup_user_fixture
    setup :setup_book_fixture

    test "returns all user books", %{book: book, user: user} do
      another_user = user_fixture()
      another_book = book_fixture(another_user, %{name: "Some other book from someone else"})
      _book_member = book_member_fixture(another_book, user)

      user_books = Books.list_books_of_user(user)
      assert [book1, book2] = Enum.sort_by(user_books, & &1.id)
      assert book1.id == book.id
      assert book2.id == another_book.id
    end
  end

  describe "create_book/2" do
    setup :setup_user_fixture

    test "creates a new book belonging to the user", %{user: user} do
      {:ok, book} = Books.create_book(user, valid_book_attributes())

      assert book.name == valid_book_name()

      assert book.default_balance_params ==
               struct!(TransferParams, valid_balance_transfer_params_attrs())

      assert %{members: [member]} = book
      assert member.user_id == user.id
    end

    test "fails when not given a name", %{user: user} do
      {:error, changeset} =
        Books.create_book(user, %{
          name: nil,
          default_balance_params: valid_balance_transfer_params_attrs()
        })

      assert errors_on(changeset) == %{name: ["can't be blank"]}
    end

    test "fails when not given balance params", %{user: user} do
      {:error, changeset} =
        Books.create_book(user, %{
          name: valid_book_name()
        })

      assert errors_on(changeset) == %{default_balance_params: ["can't be blank"]}
    end

    test "fails when given invalid balance params means code", %{user: user} do
      {:error, changeset} =
        Books.create_book(user, %{
          name: valid_book_name(),
          default_balance_params: %{means_code: :thisaintnovalidoption, params: %{}}
        })

      assert errors_on(changeset) == %{default_balance_params: ["is invalid"]}
    end

    test "fails when given invalid balance params parameters", %{user: user} do
      {:error, changeset} =
        Books.create_book(user, %{
          name: valid_book_name(),
          default_balance_params: %{means_code: :divide_equally, params: %{foo: :bar}}
        })

      assert errors_on(changeset) == %{default_balance_params: ["did not expect any parameter"]}
    end
  end

  describe "update_book/2" do
    setup :setup_user_fixture
    setup :setup_book_fixture

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
      _other_member = book_member_fixture(book, other_user)

      assert {:error, :unauthorized} = Books.update_book(book, other_user, %{name: "foo"})
    end

    test "returns error changeset with invalid data", %{book: book, user: user} do
      assert {:error, %Ecto.Changeset{}} = Books.update_book(book, user, @invalid_book_attrs)

      # TODO don't automatically insert members when creating book fixture
      # assert book == Books.get_book!(book.id)
    end
  end

  describe "delete_book/2" do
    setup :setup_user_fixture
    setup :setup_book_fixture

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
      _other_member = book_member_fixture(book, other_user)

      assert {:error, :unauthorized} = Books.delete_book(book, other_user)
    end
  end

  describe "change_book/1" do
    setup :setup_user_fixture
    setup :setup_book_fixture

    test "returns a book changeset", %{book: book} do
      assert %Ecto.Changeset{} = Books.change_book(book)
    end
  end
end
