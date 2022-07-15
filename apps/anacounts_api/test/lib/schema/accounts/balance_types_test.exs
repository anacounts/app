defmodule AnacountsAPI.Schema.Accounts.BalanceTypesTest do
  use AnacountsAPI.ConnCase

  import Anacounts.AuthFixtures
  import Anacounts.Accounts.BalanceFixtures
  import AnacountsAPI.Helpers.Tests, only: [test_logged_in: 2]

  describe "query: balance_user_params" do
    @balance_user_params_query """
    query BalanceUserParams {
      balanceUserParams {
        meansCode
        params
      }
    }
    """

    setup :setup_user_fixture
    setup :setup_log_user_in

    setup :setup_balance_user_params_fixtures

    test "returns the user params", %{conn: conn} do
      conn =
        post(conn, "/", %{
          "query" => @balance_user_params_query
        })

      assert json_response(conn, 200) == %{
               "data" => %{
                 "balanceUserParams" => [
                   %{
                     "meansCode" => "DIVIDE_EQUALLY",
                     "params" => %{}
                   }
                 ]
               }
             }
    end

    test_logged_in(@balance_user_params_query, %{})
  end

  describe "mutation: set_balance_user_params" do
    @set_balance_user_params_mutation """
    mutation SetBalanceUserParams($meansCode: BalanceMeansCode!, $params: Json!) {
      setBalanceUserParams(meansCode: $meansCode, params: $params) {
        meansCode
        params
      }
    }
    """

    setup :setup_user_fixture
    setup :setup_log_user_in

    test "returns the created user params", %{conn: conn} do
      conn =
        post(conn, "/", %{
          "query" => @set_balance_user_params_mutation,
          "variables" => %{
            "meansCode" => "DIVIDE_EQUALLY",
            "params" => "{}"
          }
        })

      assert json_response(conn, 200) == %{
               "data" => %{
                 "setBalanceUserParams" => %{
                   "meansCode" => "DIVIDE_EQUALLY",
                   "params" => %{}
                 }
               }
             }
    end

    test "updates existing user params", %{conn: conn, user: user} do
      _user_params = balance_user_params_fixtures(user)

      conn =
        post(conn, "/", %{
          "query" => @set_balance_user_params_mutation,
          "variables" => %{
            # TODO Change once possible
            "meansCode" => "DIVIDE_EQUALLY",
            "params" => "{}"
          }
        })

      assert json_response(conn, 200) == %{
               "data" => %{
                 "setBalanceUserParams" => %{
                   "meansCode" => "DIVIDE_EQUALLY",
                   "params" => %{}
                 }
               }
             }
    end

    test_logged_in(@set_balance_user_params_mutation, %{
      "meansCode" => "DIVIDE_EQUALLY",
      "params" => "{}"
    })
  end
end
