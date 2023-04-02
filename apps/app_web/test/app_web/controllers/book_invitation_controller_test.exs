defmodule AppWeb.BookInvitationControllerTest do
  use AppWeb.ConnCase

  import App.AccountsFixtures
  import App.BooksFixtures
  import App.Books.MembersFixtures

  alias App.Repo

  alias App.Books.BookMember

  @valid_invitation_email "invited@example.com"

  setup %{conn: conn} do
    book = book_fixture()
    book_member = book_member_fixture(book)

    {hashed_token, _invitation_token} =
      invitation_token_fixture(book_member, @valid_invitation_email)

    user = user_fixture(email: @valid_invitation_email)

    conn = log_in_user(conn, user)

    {:ok,
     conn: conn, book: book, book_member: book_member, hashed_token: hashed_token, user: user}
  end

  describe "GET /invitation/:token/edit" do
    test "prompts the user to join the book", %{
      conn: conn,
      book: book,
      hashed_token: hashed_token,
      user: user
    } do
      conn = get(conn, ~p"/invitation/#{hashed_token}/edit")

      assert response = html_response(conn, 200)
      assert response =~ "Hi #{user.display_name}"
      assert response =~ "You have been invited to join"
      assert response =~ book.name
      assert response =~ "Back to the app\n  </a>"
      assert response =~ "Join\n  \n\n</a>"
      assert response =~ "Disconnect\n  </a>"
    end

    test "redirects to the home page if the invitation is invalid", %{conn: conn} do
      conn = get(conn, ~p"/invitation/invalid-token/edit")

      assert redirected_to(conn) == "/"

      assert Phoenix.Flash.get(conn.assigns.flash, :error) ==
               "Invitation link is invalid or it has expired."
    end
  end

  describe "PUT /invitation/:token" do
    test "joins the user to the book", %{
      conn: conn,
      book: book,
      book_member: book_member,
      hashed_token: hashed_token,
      user: user
    } do
      conn = put(conn, ~p"/invitation/#{hashed_token}")

      assert redirected_to(conn) == ~p"/books/#{book}/transfers"

      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~ "You have been added to the book"
      assert Repo.get!(BookMember, book_member.id).user_id == user.id
    end

    test "redirects to the home page if the invitation is invalid", %{conn: conn} do
      conn = put(conn, ~p"/invitation/invalid-token")

      assert redirected_to(conn) == "/"

      assert Phoenix.Flash.get(conn.assigns.flash, :error) ==
               "Invitation link is invalid or it has expired."
    end
  end
end
