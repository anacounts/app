defmodule AppWeb.BooksLiveTest do
  use AppWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import App.BooksFixtures
  import App.Books.MembersFixtures

  setup :register_and_log_in_user

  test "lists all accounts_books", %{conn: conn, user: user} do
    book = book_fixture()
    _member = book_member_fixture(book, user_id: user.id)

    {:ok, _index_live, html} = live(conn, ~p"/books")

    assert html =~ book.name
  end

  test "filters form tunes displayed books", %{conn: conn, user: user} do
    book1 = book_fixture(name: "B", inserted_at: ~N[2020-01-01 00:00:00])
    _member1 = book_member_fixture(book1, user_id: user.id, role: :creator)

    book2 = book_fixture(name: "A", inserted_at: ~N[2020-01-02 00:00:00])
    _member2 = book_member_fixture(book2, user_id: user.id, role: :member)

    book3 = book_fixture(name: "C", inserted_at: ~N[2020-01-03 00:00:00])
    _member3 = book_member_fixture(book3, user_id: user.id, role: :creator)

    _other_book = book_fixture(name: "D", inserted_at: ~N[2020-01-04 00:00:00])

    {:ok, live, _html} = live(conn, ~p"/books")

    html =
      live
      |> form("#filters form", filters: %{sort_by: "first_created", owned_by: "me"})
      |> render_change()

    assert Floki.attribute(html, "[data-book-id]", "data-book-id") ==
             Enum.map([book1, book3], &to_string(&1.id))

    html =
      live
      |> form("#filters form", filters: %{sort_by: "alphabetically", owned_by: "anyone"})
      |> render_change()

    assert Floki.attribute(html, "[data-book-id]", "data-book-id") ==
             Enum.map([book2, book1, book3], &to_string(&1.id))
  end

  test "links to books transfers", %{conn: conn, user: user} do
    book = book_fixture()
    _member = book_member_fixture(book, user_id: user.id)

    {:ok, index_live, _html} = live(conn, ~p"/books")

    assert {:ok, _, html} =
             index_live
             |> element("[data-book-id='#{book.id}']", book.name)
             |> render_click()
             |> follow_redirect(conn, ~p"/books/#{book.id}/transfers")

    assert html =~ "Transfers"
  end
end
