defmodule AppWeb.LayoutsTest do
  use AppWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import App.BooksFixtures
  import App.Books.MembersFixtures
  import App.TransfersFixtures

  setup :register_and_log_in_user

  describe ":book" do
    test "displays the close-book button", %{conn: conn, user: user} do
      book = book_fixture()
      _member = book_member_fixture(book, user_id: user.id)

      {:ok, _live, html} = live(conn, ~p"/books/#{book}/balance")

      assert html =~ ~s(id="close-book")
      refute html =~ ~s(id="reopen-book")
    end

    test "displays the reopen-book button", %{conn: conn, user: user} do
      book = book_fixture(closed_at: ~N[2021-01-01 00:00:00])
      _member = book_member_fixture(book, user_id: user.id)

      {:ok, _live, html} = live(conn, ~p"/books/#{book}/balance")

      refute html =~ ~s(id="close-book")
      assert html =~ ~s(id="reopen-book")
    end

    test "if the book is unbalanced, ask confirmation before closing it", %{
      conn: conn,
      user: user
    } do
      book = book_fixture()
      member1 = book_member_fixture(book, user_id: user.id)
      member2 = book_member_fixture(book)

      _transfer =
        deprecated_money_transfer_fixture(book,
          amount: Money.new!(:EUR, 200),
          tenant_id: member1.id,
          peers: [%{member_id: member1.id}, %{member_id: member2.id}]
        )

      {:ok, _live, html} = live(conn, ~p"/books/#{book}/balance")

      assert Floki.attribute(html, "#close-book", "data-confirm") == [
               "The book is not balanced. Are you sure you want to close it?"
             ]
    end
  end
end
