defmodule AppWeb.BookInvitationControllerTest do
  use AppWeb.ConnCase, async: true

  import App.AccountsFixtures
  import App.BooksFixtures
  import App.Books.MembersFixtures

  alias App.Repo

  alias App.Books.BookMember

  setup %{conn: conn} do
    book = book_fixture()
    {encoded_token, _invitation_token} = invitation_token_fixture(book)

    user = user_fixture()

    conn = log_in_user(conn, user)

    {:ok, conn: conn, book: book, encoded_token: encoded_token, user: user}
  end

  describe "GET /invitations/:token" do
    test "prompts the user to join the book", %{
      conn: conn,
      book: book,
      encoded_token: encoded_token,
      user: user
    } do
      conn = get(conn, ~p"/invitations/#{encoded_token}")

      assert response = html_response(conn, 200)
      assert response =~ "Hi #{user.display_name}"
      assert response =~ "You have been invited to join"
      assert response =~ book.name

      # TODO(v2,book invitation)
      # assert response =~
      #          ~s(input type="hidden" name="book_member[id]" id="book_member_id" value="new")

      assert response =~ "Back to the app\n  </a>"
      assert response =~ "Join\n    \n</button>"
      assert response =~ "Disconnect\n  </a>"
    end

    test "displays the existing members if any", %{
      conn: conn,
      book: book,
      encoded_token: encoded_token
    } do
      book_member = book_member_fixture(book)

      conn = get(conn, ~p"/invitations/#{encoded_token}")

      assert response = html_response(conn, 200)
      assert response =~ book_member.nickname
      assert response =~ ~s(input type="radio" name="book_member[id]" value="#{book_member.id}")
    end

    test "redirects to the home page if the invitation is invalid", %{conn: conn} do
      conn = get(conn, ~p"/invitations/invalid-token")

      assert redirected_to(conn) == "/"

      assert Phoenix.Flash.get(conn.assigns.flash, :error) ==
               "Invitation link is invalid or it has expired"
    end
  end

  describe "PUT /invitations/:token" do
    test "join as an existing unlinked member", %{
      conn: conn,
      book: book,
      encoded_token: encoded_token,
      user: user
    } do
      book_member = book_member_fixture(book)

      conn =
        put(conn, ~p"/invitations/#{encoded_token}", %{
          book_member: %{
            id: book_member.id
          }
        })

      assert redirected_to(conn) == ~p"/books/#{book}/transfers"
      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~ "You have been added to the book"

      book_member = Repo.reload(book_member)
      assert book_member.user_id == user.id
    end

    test "join as a new member", %{
      conn: conn,
      book: book,
      encoded_token: encoded_token,
      user: user
    } do
      conn =
        put(conn, ~p"/invitations/#{encoded_token}", %{
          book_member: %{
            id: "new"
          }
        })

      assert redirected_to(conn) == ~p"/books/#{book}/transfers"
      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~ "You have been added to the book"

      book_member = Repo.get_by!(BookMember, book_id: book.id, user_id: user.id)
      assert book_member.role == :member
      assert book_member.nickname == user.display_name
    end

    test "redirects to the home page if the invitation is invalid", %{conn: conn} do
      conn = put(conn, ~p"/invitations/invalid-token")

      assert redirected_to(conn) == "/"

      assert Phoenix.Flash.get(conn.assigns.flash, :error) ==
               "Invitation link is invalid or it has expired"
    end
  end
end
