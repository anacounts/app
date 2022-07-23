defmodule AppWeb.PageControllerTest do
  use AppWeb.ConnCase

  import App.AuthFixtures

  describe "GET :index" do
    test "redirects authenticated user to home page", %{conn: conn} do
      user = user_fixture()
      conn = log_in_user(conn, user)

      conn = get(conn, Routes.page_path(conn, :index))
      assert redirected_to(conn) == Routes.book_index_path(conn, :index)
    end

    test "redirects non-authenticated user to new session page", %{conn: conn} do
      conn = get(conn, Routes.page_path(conn, :index))
      assert redirected_to(conn) == Routes.user_session_path(conn, :new)
    end
  end
end
