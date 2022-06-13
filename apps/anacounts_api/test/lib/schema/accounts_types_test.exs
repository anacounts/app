defmodule AnacountsAPI.Schema.AccountsTypesTest do
  use AnacountsAPI.ConnCase

  import Anacounts.AuthFixtures
  import Anacounts.AccountsFixtures
  import AnacountsAPI.Helpers.Tests, only: [test_logged_in: 2]

  alias Anacounts.Accounts

  describe "query: book" do
    @book_query """
    query Book($id: ID!) {
      book(id: $id) {
        id
        name
        insertedAt
        members {
          id
          role
        }
      }
    }
    """

    setup :setup_user_fixture
    setup :setup_log_user_in

    setup :setup_book_fixture

    test "returns the book information", %{conn: conn, book: book, user: user} do
      conn =
        post(conn, "/api/v1", %{
          "query" => @book_query,
          "variables" => %{"id" => book.id}
        })

      assert json_response(conn, 200) == %{
               "data" => %{
                 "book" => %{
                   "id" => to_string(book.id),
                   "name" => valid_book_name(),
                   "insertedAt" => NaiveDateTime.to_iso8601(book.inserted_at),
                   "members" => [
                     %{
                       "id" => to_string(user.id),
                       "role" => "creator"
                     }
                   ]
                 }
               }
             }
    end

    test "returns an error if the book does not exist", %{conn: conn} do
      conn =
        post(conn, "/api/v1", %{
          "query" => @book_query,
          "variables" => %{"id" => "0"}
        })

      assert json_response(conn, 200) == %{
               "data" => %{"book" => nil},
               "errors" => [
                 %{
                   "locations" => [%{"column" => 3, "line" => 2}],
                   "message" => "Not found",
                   "path" => ["book"]
                 }
               ]
             }
    end

    test "returns an error if the book does not belong to the user", %{conn: conn} do
      other_user = user_fixture()
      other_book = book_fixture(other_user)

      conn =
        post(conn, "/api/v1", %{
          "query" => @book_query,
          "variables" => %{"id" => other_book.id}
        })

      assert json_response(conn, 200) == %{
               "data" => %{"book" => nil},
               "errors" => [
                 %{
                   "locations" => [%{"column" => 3, "line" => 2}],
                   "message" => "Not found",
                   "path" => ["book"]
                 }
               ]
             }
    end

    test_logged_in(@book_query, %{"id" => "0"})
  end

  describe "mutation: create_book" do
    @create_book_mutation """
    mutation CreateBook($attrs: BookInput!) {
      createBook(attrs: $attrs) {
        id
        name
        insertedAt
        members {
          id
          role
        }
      }
    }
    """

    setup :setup_user_fixture
    setup :setup_log_user_in

    test "create a new book", %{conn: conn, user: user} do
      conn =
        post(conn, "/api/v1", %{
          "query" => @create_book_mutation,
          "variables" => %{"attrs" => valid_book_attributes()}
        })

      user_id = to_string(user.id)

      assert %{
               "data" => %{
                 "createBook" => %{
                   "id" => book_id,
                   "name" => _book_name,
                   "insertedAt" => _inserted_at,
                   "members" => [
                     %{
                       "id" => ^user_id,
                       "role" => "creator"
                     }
                   ]
                 }
               }
             } = json_response(conn, 200)

      assert Accounts.get_book(book_id, user)
    end

    test_logged_in(@create_book_mutation, %{"attrs" => valid_book_attributes()})
  end

  describe "mutation: delete_book" do
    @delete_book_mutation """
    mutation DeleteBook($id: ID!) {
      deleteBook(id: $id) {
        id
      }
    }
    """

    setup :setup_user_fixture
    setup :setup_log_user_in

    setup :setup_book_fixture

    test "deletes the book", %{conn: conn, book: book} do
      conn =
        post(conn, "/api/v1", %{
          "query" => @delete_book_mutation,
          "variables" => %{"id" => book.id}
        })

      assert json_response(conn, 200) == %{
               "data" => %{"deleteBook" => %{"id" => to_string(book.id)}}
             }
    end

    test "errors with `:not_found` if it does not exist", %{conn: conn} do
      conn =
        post(conn, "/api/v1", %{
          "query" => @delete_book_mutation,
          "variables" => %{"id" => 0}
        })

      assert json_response(conn, 200) == %{
               "data" => %{"deleteBook" => nil},
               "errors" => [
                 %{
                   "locations" => [%{"column" => 3, "line" => 2}],
                   "message" => "Not found",
                   "path" => ["deleteBook"]
                 }
               ]
             }
    end

    test "errors with `:not_found` if it does not belong to the user", %{conn: conn} do
      remote_user = user_fixture()
      book = book_fixture(remote_user)

      conn =
        post(conn, "/api/v1", %{
          "query" => @delete_book_mutation,
          "variables" => %{"id" => book.id}
        })

      assert json_response(conn, 200) == %{
               "data" => %{"deleteBook" => nil},
               "errors" => [
                 %{
                   "locations" => [%{"column" => 3, "line" => 2}],
                   "message" => "Not found",
                   "path" => ["deleteBook"]
                 }
               ]
             }
    end

    # XXX Add when it's possible to add a book member
    # test "errors with `:unauthorized` if the user does not have `:delete_book` right", %{user: user}

    test_logged_in(@delete_book_mutation, %{"id" => "0"})
  end
end
