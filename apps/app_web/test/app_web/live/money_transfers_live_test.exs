defmodule AppWeb.MoneyTransfersLiveTest do
  use AppWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import App.BooksFixtures
  import App.Books.MembersFixtures
  import App.TransfersFixtures

  alias App.Repo

  alias App.Books

  setup [:register_and_log_in_user, :book_with_member_context]

  test "transfers tab is highlighted", %{conn: conn, book: book} do
    {:ok, _live, html} = live(conn, ~p"/books/#{book}/transfers")

    assert [class] =
             Floki.attribute(
               html,
               ~s(.tabs__link[href="#{~p"/books/#{book}/transfers"}"]),
               "class"
             )

    assert String.contains?(class, "tabs__link--active")
  end

  test "lists book money transfers", %{conn: conn, book: book, member: member} do
    money_transfer = money_transfer_fixture(book, tenant_id: member.id)

    other_book = book_fixture()

    other_money_transfer =
      money_transfer_fixture(other_book,
        tenant_id: member.id,
        label: "Other book money transfer"
      )

    {:ok, _index_live, html} = live(conn, ~p"/books/#{book}/transfers")

    assert html =~ "Transfers"
    assert html =~ money_transfer.label
    refute html =~ other_money_transfer.label
  end

  test "allows to go to edit form", %{conn: conn, book: book, member: member} do
    money_transfer = money_transfer_fixture(book, tenant_id: member.id)

    {:ok, index_live, html} = live(conn, ~p"/books/#{book}/transfers")

    assert html =~ "Transfers"
    assert html =~ money_transfer.label

    {:ok, _edit_live, html} =
      index_live
      |> element(".tile__button", "Edit")
      |> render_click()
      |> follow_redirect(conn, ~p"/books/#{book}/transfers/#{money_transfer}/edit")

    assert html =~ "Edit"
    assert html =~ "<form"
    assert html =~ money_transfer.label
  end

  test "allows to delete a transfer", %{conn: conn, book: book, member: member} do
    money_transfer = money_transfer_fixture(book, tenant_id: member.id)

    {:ok, index_live, html} = live(conn, ~p"/books/#{book}/transfers")

    assert html =~ "Transfers"
    assert html =~ money_transfer.label

    html =
      index_live
      |> element(".tile__button", "Delete")
      |> render_click()

    refute html =~ money_transfer.label
  end

  test "deletes book", %{conn: conn, book: book} do
    {:ok, show_live, _html} = live(conn, ~p"/books/#{book}/transfers")

    assert {:ok, _, html} =
             show_live
             |> element("#delete-book", "Delete")
             |> render_click()
             |> follow_redirect(conn, ~p"/books")

    assert html =~ "Book deleted successfully"
    refute html =~ book.name
  end

  test "closes book", %{conn: conn, book: book} do
    {:ok, live, _html} = live(conn, ~p"/books/#{book}/transfers")

    assert html =
             live
             |> element("#close-book", "Close")
             |> render_click()

    assert html =~ "Book closed successfully"
    assert book |> Repo.reload() |> Books.closed?()
  end

  test "reopens book", %{conn: conn, book: book} do
    book = Books.close_book!(book)

    {:ok, live, _html} = live(conn, ~p"/books/#{book}/transfers")

    assert html =
             live
             |> element("#reopen-book", "Reopen")
             |> render_click()

    assert html =~ "Book reopened successfully"
    refute book |> Repo.reload() |> Books.closed?()
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
