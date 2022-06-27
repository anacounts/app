defmodule AnacountsAPI.Helpers.Tests do
  @moduledoc """
  Define helpers for commonly used tests, not to rewrite them everytime.
  """

  @doc """
  Check that a query requires a user to be logged in.
  NB: if a header "authorization" is set on the conn, it will be
  remove before running the query.

  ## Example
      describe "query: profile" do
        @profile_query "..."

        test_logged_in(@profile_query, %{})

        # with variables
        @book_query "..."

        test_logged_in(@book_query, %{"id" => "0"})
      end
  """
  defmacro test_logged_in(query, variables) do
    quote do
      test "requires user to be logged in", %{conn: conn} do
        # delete the "authorization" header in the case a setup automatically
        # logs a user in for this test
        conn = Plug.Conn.delete_req_header(conn, "authorization")

        conn =
          post(conn, "/", %{
            "query" => unquote(query),
            "variables" => unquote(variables)
          })

        assert match?(
                 %{"errors" => [%{"message" => "You must be logged in"}]},
                 json_response(conn, 200)
               )
      end
    end
  end
end
