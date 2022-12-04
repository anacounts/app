defmodule AppWeb.InvitationLiveTest do
  use AppWeb.ConnCase

  import Phoenix.LiveViewTest
  import Swoosh.TestAssertions

  import App.AuthFixtures
  import App.BooksFixtures
  import App.Books.MembersFixtures

  alias App.Repo

  alias App.Books.BookMember
  alias App.Books.InvitationToken

  describe "Index" do
    setup [:register_and_log_in_user, :book_with_member_context]

    test "creates a new book member", %{conn: conn, book: book} do
      {:ok, index_live, _html} = live(conn, Routes.invitation_index_path(conn, :index, book))

      assert index_live
             |> form("#invite-member", %{book_member: %{nickname: "New Member"}, send_to: ""})
             |> render_submit() =~ "Member added"

      assert Repo.get_by(BookMember, nickname: "New Member")
      refute_email_sent()
    end

    test "sends invitation email", %{conn: conn, book: book} do
      {:ok, index_live, _html} = live(conn, Routes.invitation_index_path(conn, :index, book))

      assert index_live
             |> form("#invite-member", %{
               book_member: %{nickname: "New Member"},
               send_to: "invited@example.com"
             })
             |> render_submit() =~ "Invitation sent"

      assert book_member = Repo.get_by(BookMember, nickname: "New Member")
      assert Repo.get_by(InvitationToken, book_member_id: book_member.id)
      assert_email_sent()
    end

    test "shows suggestion list", %{conn: conn, book: book, user: user} do
      # `user` and `other_user` are both in `other_book`, so `other_user` should be
      # in `book` invitation suggestions
      other_book = book_fixture()
      _member = book_member_fixture(other_book, user_id: user.id)

      other_user = user_fixture(display_name: "Other User")
      _member = book_member_fixture(other_book, user_id: other_user.id)

      {:ok, _index_live, html} = live(conn, Routes.invitation_index_path(conn, :index, book))

      assert html =~ other_user.display_name
      refute html =~ user.display_name
    end

    test "does not show suggestions if the list is empty", %{conn: conn, book: book} do
      {:ok, _index_live, html} = live(conn, Routes.invitation_index_path(conn, :index, book))

      refute html =~ "Suggestions"
    end

    test "invites members from suggestion list", %{conn: conn, book: book, user: user} do
      # `user` and `other_user` are both in `other_book`, so `other_user` should be
      # in `book` invitation suggestions
      other_book = book_fixture()
      _member = book_member_fixture(other_book, user_id: user.id)

      other_user = user_fixture(display_name: "Other User")
      _member = book_member_fixture(other_book, user_id: other_user.id)

      {:ok, index_live, _html} = live(conn, Routes.invitation_index_path(conn, :index, book))

      assert index_live
             |> element("button[phx-value-id=#{other_user.id}]", "Invite")
             |> render_click() =~ "Invitation sent"

      assert book_member = Repo.get_by(BookMember, nickname: other_user.display_name)
      assert Repo.get_by(InvitationToken, book_member_id: book_member.id)
      assert_email_sent()
    end
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
