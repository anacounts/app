defmodule AppWeb.BookMembersLiveTest do
  use AppWeb.ConnCase

  import Phoenix.LiveViewTest
  import App.AccountsFixtures
  import App.BooksFixtures
  import App.Books.MembersFixtures

  setup [:register_and_log_in_user, :book_with_member_context]

  test "displays book members", %{conn: conn, book: book} do
    _member = book_member_fixture(book, user_id: user_fixture(display_name: "Samuel").id)

    {:ok, _show_live, html} = live(conn, ~p"/books/#{book}/members")

    # the book name is the main title
    assert html =~ book.name <> "\n</h1>"
    # the tabs are displayed
    assert html =~ "Members"
    # there are links that go to the invitation and member creation pages
    assert html =~ ~s(href="#{~p|/books/#{book}/invite|}")
    assert html =~ ~s(href="#{~p|/books/#{book}/members/new|}")
    assert html =~ "Samuel"
  end

  test "tiles navigate to the member page", %{conn: conn, book: book} do
    member = book_member_fixture(book)

    {:ok, live, _html} = live(conn, ~p"/books/#{book}/members")

    assert {:ok, _live, _html} =
             live
             |> element(".tile", member.nickname)
             |> render_click()
             |> follow_redirect(conn, ~p"/books/#{book}/members/#{member}")
  end

  test "deletes book", %{conn: conn, book: book} do
    {:ok, show_live, _html} = live(conn, ~p"/books/#{book}/members")

    assert {:ok, _, html} =
             show_live
             |> element("#delete-book", "Delete")
             |> render_click()
             |> follow_redirect(conn, ~p"/books")

    assert html =~ "Book deleted successfully"
    refute html =~ book.name
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
