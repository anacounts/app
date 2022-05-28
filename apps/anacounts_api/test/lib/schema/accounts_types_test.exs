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
          email
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
                       "email" => user.email,
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
          email
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
      user_email = user.email

      assert %{
               "data" => %{
                 "createBook" => %{
                   "id" => book_id,
                   "name" => _book_name,
                   "insertedAt" => _inserted_at,
                   "members" => [
                     %{
                       "id" => ^user_id,
                       "email" => ^user_email,
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
end
