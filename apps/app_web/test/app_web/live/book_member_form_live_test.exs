defmodule AppWeb.BookMemberFormLiveTest do
  use AppWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import App.BooksFixtures
  import App.Books.MembersFixtures

  alias App.Repo

  alias App.Books.BookMember

  setup [:register_and_log_in_user, :book_with_member_context]

  describe "/books/:book_id/members/new" do
    test "show the member new page", %{conn: conn, book: book} do
      {:ok, live, _html} = live(conn, ~p"/books/#{book}/members/new")

      assert {:ok, _live, _html} =
               live
               |> form("form", book_member: %{nickname: "Nickname"})
               |> render_submit()
               |> follow_redirect(conn)

      assert member = Repo.get_by!(BookMember, book_id: book.id, nickname: "Nickname")
      assert member.book_id == book.id
    end
  end

  describe "/books/:book_id/members/:member_id/edit" do
    test "shows the member edit page", %{conn: conn, book: book, member: member} do
      {:ok, live, _html} = live(conn, ~p"/books/#{book}/members/#{member}/edit")

      {:ok, _live, _html} =
        live
        |> form("form", book_member: %{nickname: "Updated Nickname"})
        |> render_submit()
        |> follow_redirect(conn, ~p"/books/#{book}/members/#{member}")

      member = Repo.reload(member)
      assert member.nickname == "Updated Nickname"
    end

    test "responds with not found if the book or member does not exist", %{
      conn: conn,
      book: book,
      member: member
    } do
      assert_raise Ecto.NoResultsError, fn ->
        live(conn, ~p"/books/0/members/#{member}/edit")
      end

      assert_raise Ecto.NoResultsError, fn ->
        live(conn, ~p"/books/#{book}/members/0/edit")
      end
    end

    test "responds with not found if the book member does not belongs to the book", %{
      conn: conn,
      book: book
    } do
      other_member = book_member_fixture(book_fixture())

      assert_raise Ecto.NoResultsError, fn ->
        live(conn, ~p"/books/#{book}/members/#{other_member}/edit")
      end
    end
  end

  test "validates the form fields", %{conn: conn, book: book, member: member} do
    {:ok, live, _html} = live(conn, ~p"/books/#{book}/members/#{member}/edit")

    assert live
           |> form("form", book_member: %{nickname: ""})
           |> render_submit() =~ "can&#39;t be blank"
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
