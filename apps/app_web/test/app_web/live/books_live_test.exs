defmodule AppWeb.BooksLiveTest do
  use AppWeb.ConnCase

  import Phoenix.LiveViewTest
  import App.BooksFixtures
  import App.Books.MembersFixtures

  setup [:register_and_log_in_user, :book_with_member_context]

  test "lists all accounts_books", %{conn: conn, book: book} do
    {:ok, _index_live, html} = live(conn, ~p"/books")

    assert html =~ book.name
  end

  test "links to books transfers", %{conn: conn, book: book} do
    {:ok, index_live, _html} = live(conn, ~p"/books")

    assert {:ok, _, html} =
             index_live
             |> element("[data-book-id='#{book.id}']", book.name)
             |> render_click()
             |> follow_redirect(conn, ~p"/books/#{book.id}/transfers")

    assert html =~ "Transfers"
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
