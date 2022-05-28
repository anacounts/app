defmodule AnacountsAPI.Schema.AuthTypesTest do
  use AnacountsAPI.ConnCase

  import Anacounts.AuthFixtures
  import AnacountsAPI.Helpers.Tests, only: [test_logged_in: 2]

  describe "query: profile" do
    @profile_query """
    query GetProfile {
      profile {
        id
        email
        confirmedAt
        displayName
        avatarUrl
      }
    }
    """

    test "returns information about the logged user", %{conn: conn} do
      # define the email so the Gravatar based avatarUrl,
      # which is computed using the user email, doesn't change everytime
      user = user_fixture(%{email: "email@example.com"})
      conn = log_user_in(conn, user)

      conn = post(conn, "/api/v1", %{"query" => @profile_query})

      assert json_response(conn, 200) == %{
               "data" => %{
                 "profile" => %{
                   "id" => to_string(user.id),
                   "email" => user.email,
                   "confirmedAt" => nil,
                   "displayName" => nil,
                   "avatarUrl" =>
                     "https://www.gravatar.com/avatar/5658ffccee7f0ebfda2b226238b1eb6e"
                 }
               }
             }
    end

    test_logged_in(@profile_query, %{})
  end

  describe "mutation: log_in" do
    @log_in_mutation """
    mutation LogIn($email: String!, $password: String!) {
      logIn(email: $email, password: $password)
    }
    """

    setup :setup_user_fixture

    test "returns a authentication token", %{conn: conn, user: user} do
      conn =
        post(conn, "/api/v1", %{
          "query" => @log_in_mutation,
          "variables" => %{
            email: user.email,
            password: valid_user_password()
          }
        })

      response = json_response(conn, 200)

      assert %{"data" => %{"logIn" => token}} = response
      refute is_nil(token)
      refute match?(%{"errors" => _errors}, response)
    end

    test "returns error on incorrect email", %{conn: conn} do
      conn =
        post(conn, "/api/v1", %{
          "query" => @log_in_mutation,
          "variables" => %{
            email: "anacounts@example.com",
            password: valid_user_password()
          }
        })

      assert json_response(conn, 200) == %{
               "data" => %{"logIn" => nil},
               "errors" => [
                 %{
                   "locations" => [%{"column" => 3, "line" => 2}],
                   "message" => "incorrect email or password",
                   "path" => ["logIn"]
                 }
               ]
             }
    end

    test "returns error on incorrect password", %{conn: conn, user: user} do
      conn =
        post(conn, "/api/v1", %{
          "query" => @log_in_mutation,
          "variables" => %{
            email: user.email,
            password: "somekindofsuperpassword"
          }
        })

      assert json_response(conn, 200) == %{
               "data" => %{"logIn" => nil},
               "errors" => [
                 %{
                   "locations" => [%{"column" => 3, "line" => 2}],
                   "message" => "incorrect email or password",
                   "path" => ["logIn"]
                 }
               ]
             }
    end
  end

  describe "mutation: register" do
    @register_mutation """
    mutation Register($email: String!, $password: String!) {
      register(email: $email, password: $password)
    }
    """

    test "register a new user", %{conn: conn} do
      conn =
        post(conn, "/api/v1", %{
          "query" => @register_mutation,
          "variables" => valid_register_attributes()
        })

      assert json_response(conn, 200) == %{
               "data" => %{"register" => "confirmation instructions sent"}
             }
    end

    test "fails with invalid attributes", %{conn: conn} do
      conn =
        post(conn, "/api/v1", %{
          "query" => @register_mutation,
          "variables" => %{
            email: unique_user_email(),
            password: "Curabitur bibendum mattis massa ac dictum. Vestibulum venenatis nulla sit."
          }
        })

      assert json_response(conn, 200) == %{
               "data" => %{"register" => nil},
               "errors" => [
                 %{
                   "locations" => [%{"column" => 3, "line" => 2}],
                   "message" => "password: should be at most 72 character(s)",
                   "path" => ["register"]
                 }
               ]
             }
    end
  end

  describe "mutation: update_profile" do
    @update_profile_mutation """
    mutation UpdateProfile($attrs: ProfileInput!) {
      updateProfile(attrs: $attrs) {
        displayName
      }
    }
    """

    setup :setup_user_fixture
    setup :setup_log_user_in

    test "changes user profile attributes", %{conn: conn} do
      conn =
        post(conn, "/api/v1", %{
          "query" => @update_profile_mutation,
          "variables" => %{
            "attrs" => %{
              "displayName" => "JohnDoe"
            }
          }
        })

      assert json_response(conn, 200) == %{
               "data" => %{"updateProfile" => %{"displayName" => "JohnDoe"}}
             }
    end

    test "fails if given invalid attributes", %{conn: conn} do
      conn =
        post(conn, "/api/v1", %{
          "query" => @update_profile_mutation,
          "variables" => %{
            "attrs" => %{
              "displayName" => nil
            }
          }
        })

      assert json_response(conn, 200) == %{
               "errors" => [
                 %{
                   "locations" => [%{"column" => 17, "line" => 2}],
                   "message" =>
                     "Argument \"attrs\" has invalid value $attrs.\nIn field \"displayName\": Expected type \"String!\", found null."
                 }
               ]
             }
    end

    test_logged_in(@profile_query, %{})
  end
end
