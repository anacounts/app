defmodule AppWeb.BookLiveTest do
  use AppWeb.ConnCase

  import Phoenix.LiveViewTest
  import App.BooksFixtures

  @create_attrs %{
    name: "some name",
    default_balance_params: %{"means_code" => "divide_equally"}
  }
  @update_attrs %{
    name: "some updated name",
    default_balance_params: %{"means_code" => "weight_by_income"}
  }
  @invalid_attrs %{name: "", default_balance_params: %{"means_code" => "weight_by_income"}}

  describe "Form" do
    setup [:register_and_log_in_user, :setup_book_fixture]

    test "saves new book", %{conn: conn} do
      {:ok, index_live, _html} = live(conn, Routes.book_form_path(conn, :new))

      assert index_live
             |> form("#book-form", book: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      {:ok, _, html} =
        index_live
        |> form("#book-form", book: @create_attrs)
        |> render_submit()
        |> follow_redirect(conn)

      assert html =~ "some name"
    end

    test "updates book", %{conn: conn, book: book} do
      {:ok, index_live, _html} = live(conn, Routes.book_form_path(conn, :edit, book))

      assert index_live
             |> form("#book-form", book: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      {:ok, _, html} =
        index_live
        |> form("#book-form", book: @update_attrs)
        |> render_submit()
        |> follow_redirect(conn, Routes.book_show_path(conn, :show, book))

      assert html =~ "some updated name"
    end
  end

  describe "Index" do
    setup [:register_and_log_in_user, :setup_book_fixture]

    test "lists all accounts_books", %{conn: conn, book: book} do
      {:ok, _index_live, html} = live(conn, Routes.book_index_path(conn, :index))

      assert html =~ "1 book in your list"
      assert html =~ book.name
    end
  end

  describe "Show" do
    setup [:register_and_log_in_user, :setup_book_fixture]

    test "displays book", %{conn: conn, book: book} do
      {:ok, _show_live, html} = live(conn, Routes.book_show_path(conn, :show, book))

      assert html =~ "Book"
      assert html =~ book.name
    end

    test "deletes book", %{conn: conn, book: book} do
      {:ok, show_live, _html} = live(conn, Routes.book_show_path(conn, :show, book))

      assert {:ok, _, html} =
               show_live
               |> element("#delete-book", "Delete")
               |> render_click()
               |> follow_redirect(conn, Routes.book_index_path(conn, :index))

      assert html =~ "Book deleted successfully"
      refute html =~ book.name
    end
  end
end
