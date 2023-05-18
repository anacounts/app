defmodule AppWeb.BookFormLiveTest do
  use AppWeb.ConnCase

  import Phoenix.LiveViewTest
  import App.BooksFixtures
  import App.Books.MembersFixtures

  @create_attrs %{
    name: "some name",
    default_balance_params: %{"means_code" => "divide_equally"}
  }
  @update_attrs %{
    name: "some updated name",
    default_balance_params: %{"means_code" => "weight_by_income"}
  }
  @invalid_attrs %{name: "", default_balance_params: %{"means_code" => "weight_by_income"}}

  setup [:register_and_log_in_user, :book_with_member_context]

  test "saves new book", %{conn: conn} do
    {:ok, index_live, _html} = live(conn, ~p"/books/new")

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
    {:ok, index_live, _html} = live(conn, ~p"/books/#{book}/edit")

    assert index_live
           |> form("#book-form", book: @invalid_attrs)
           |> render_change() =~ "can&#39;t be blank"

    {:ok, _, html} =
      index_live
      |> form("#book-form", book: @update_attrs)
      |> render_submit()
      |> follow_redirect(conn, ~p"/books/#{book}/transfers")

    assert html =~ "some updated name"
  end

  # Depends on :register_and_log_in_user
  defp book_with_member_context(%{user: user} = context) do
    book = book_fixture()
    member = book_member_fixture(book, user_id: user.id, role: :creator)

    Map.merge(context, %{
      book: book,
      member: member
    })
  end
end
