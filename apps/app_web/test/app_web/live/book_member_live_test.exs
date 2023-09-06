defmodule AppWeb.BookMemberLiveTest do
  use AppWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import App.Books.MembersFixtures
  import App.BooksFixtures
  import App.TransfersFixtures

  setup [:register_and_log_in_user, :book_with_member_context]

  test "show a member page", %{conn: conn, book: book, member: member, user: user} do
    {:ok, _live, html} = live(conn, ~p"/books/#{book}/members/#{member}")

    # avatar, display name and email are displayed
    assert html =~ ~s(class="avatar)
    assert html =~ "#{user.display_name}</span><span>(#{member.nickname})"
    assert html =~ user.email

    # balance is displayed
    assert html =~ "€0.00"

    # creation date is displayed
    assert html =~ ~r/Created on \d{2}-\d{2}-\d{4}/
  end

  test "shows an unlinked member page", %{conn: conn, book: book} do
    member1 = book_member_fixture(book)
    member2 = book_member_fixture(book)

    money_transfer_fixture(book,
      amount: Money.new(200, :EUR),
      tenant_id: member1.id,
      peers: [%{member_id: member1.id}, %{member_id: member2.id}]
    )

    {:ok, _live, html} = live(conn, ~p"/books/#{book}/members/#{member1}")

    assert html =~ "person_off"
    assert html =~ member1.nickname

    assert html =~ "€1.00"
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
