defmodule AnacountsAPI.Schema.TransfersTypesTest do
  use AnacountsAPI.ConnCase

  import Anacounts.AuthFixtures
  import Anacounts.AccountsFixtures
  import Anacounts.TransfersFixtures
  import AnacountsAPI.Helpers.Tests, only: [test_logged_in: 2]

  describe "mutation: create_money_transfer" do
    @create_money_transfer_mutation """
    mutation CreateMoneyTransfer($attrs: MoneyTransferCreationInput!) {
      createMoneyTransfer(attrs: $attrs) {
        amount
        type
        date

        peers {
          weight
        }
      }
    }
    """

    setup :setup_user_fixture
    setup :setup_log_user_in

    setup :setup_book_fixture
    setup :setup_book_member_fixture

    test "create a money transfer", %{conn: conn, book: book, book_member: book_member} do
      conn =
        post(conn, "/", %{
          "query" => @create_money_transfer_mutation,
          "variables" => %{
            "attrs" => %{
              "bookId" => book.id,
              "amount" => "1999/EUR",
              "date" => "2022-02-10T23:04:12Z",
              "type" => "INCOME",
              "peers" => [
                %{"memberId" => book_member.id}
              ]
            }
          }
        })

      assert json_response(conn, 200) == %{
               "data" => %{
                 "createMoneyTransfer" => %{
                   "amount" => "1999/EUR",
                   "date" => "2022-02-10T23:04:12Z",
                   "type" => "INCOME",
                   "peers" => [
                     %{"weight" => "1"}
                   ]
                 }
               }
             }
    end

    test "today as default date", %{conn: conn, book: book} do
      conn =
        post(conn, "/", %{
          "query" => @create_money_transfer_mutation,
          "variables" => %{
            "attrs" => %{
              "bookId" => book.id,
              "amount" => "399/USD",
              "type" => "REIMBURSEMENT"
            }
          }
        })

      assert response = json_response(conn, 200)
      assert response["data"]["createMoneyTransfer"]["date"]
    end

    test "cannot create for a book the user isn't member of", %{conn: conn} do
      other_user = user_fixture()
      other_book = book_fixture(other_user)

      conn =
        post(conn, "/", %{
          "query" => @create_money_transfer_mutation,
          "variables" => %{
            "attrs" => %{
              "bookId" => other_book.id,
              "amount" => "199/AED",
              "type" => "PAYMENT",
              "peers" => []
            }
          }
        })

      assert json_response(conn, 200) == %{
               "data" => %{"createMoneyTransfer" => nil},
               "errors" => [
                 %{
                   "locations" => [%{"column" => 3, "line" => 2}],
                   "message" => "Not found",
                   # TODO path could be enhanced to ["createMoneyTransfer", "bookId"]
                   "path" => ["createMoneyTransfer"]
                 }
               ]
             }
    end

    test_logged_in(@create_money_transfer_mutation, %{
      "attrs" => %{"bookId" => 0, "amount" => "0/EUR", "type" => "INCOME"}
    })
  end

  describe "mutation: update_money_transfer" do
    @update_money_transfer_mutation """
    mutation UpdateMoneyTransfer($transferId: ID!, $attrs: MoneyTransferUpdateInput!) {
      updateMoneyTransfer(transferId: $transferId, attrs: $attrs) {
        amount
        type
        date

        peers {
          weight
        }
      }
    }
    """

    setup :setup_user_fixture
    setup :setup_log_user_in

    setup :setup_book_fixture
    setup :setup_book_member_fixture
    setup :setup_money_transfer_fixture

    test "updates the money transfer", %{conn: conn, book: book, money_transfer: money_transfer} do
      other_user = user_fixture()
      other_member = book_member_fixture(book, other_user)

      conn =
        post(conn, "/", %{
          "query" => @update_money_transfer_mutation,
          "variables" => %{
            "transferId" => money_transfer.id,
            "attrs" => %{
              "date" => "2024-04-04T04:04:04Z",
              "amount" => "280/ALL",
              "peers" => [
                %{"memberId" => other_member.id, "weight" => "3"}
              ]
            }
          }
        })

      assert json_response(conn, 200) == %{
               "data" => %{
                 "updateMoneyTransfer" => %{
                   "amount" => "280/ALL",
                   "type" => "PAYMENT",
                   "date" => "2024-04-04T04:04:04Z",
                   "peers" => [
                     %{"weight" => "3"}
                   ]
                 }
               }
             }
    end

    test "cannot update a trasnfer belonging to book the user isn't member of", %{
      conn: conn,
      money_transfer: money_transfer
    } do
      other_user = user_fixture()
      conn = log_user_in(conn, other_user)

      conn =
        post(conn, "/", %{
          "query" => @update_money_transfer_mutation,
          "variables" => %{
            "transferId" => money_transfer.id,
            "attrs" => %{
              "amount" => "9810/EEK",
              "date" => "2025-05-05T05:05:05Z"
            }
          }
        })

      assert json_response(conn, 200) == %{
               "data" => %{"updateMoneyTransfer" => nil},
               "errors" => [
                 %{
                   "locations" => [%{"column" => 3, "line" => 2}],
                   "message" => "Not found",
                   # TODO path could be enhanced to ["createMoneyTransfer", "bookId"]
                   "path" => ["updateMoneyTransfer"]
                 }
               ]
             }
    end

    test_logged_in(@update_money_transfer_mutation, %{"transferId" => 0, "attrs" => %{}})
  end
end
