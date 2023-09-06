defmodule AppWeb.BookInvitationController do
  @moduledoc """
  Let users join books by opening invitations.

  This controller is responsible for handling any requests that match
  `/invitations/:token`, where `:token` is the token of the invitation. When an invitation
  is open, the user is asked the member they want to join as. If the member is new, a new
  member is created and linked to the user. If the member already exists, the user is
  linked to the existing member.
  """

  use AppWeb, :controller

  alias App.Books
  alias App.Books.Members

  plug :get_book_by_token
  plug :ensure_user_is_not_member_of_book
  plug :put_layout, html: :auth

  def edit(conn, _opts) do
    book = conn.assigns.book
    members = Members.list_unlinked_members_of_book(book)

    render(conn, :edit,
      page_title: gettext("Join %{book_name}", book_name: book.name),
      book: book,
      members: members,
      form: to_form(%{"id" => ""}, as: :book_member)
    )
  end

  def update(conn, %{"book_member" => %{"id" => book_member_id}}) do
    %{book: book, current_user: current_user} = conn.assigns

    if book_member_id == "new" do
      Members.create_book_member_for_user(book, current_user)
    else
      book_member_id
      |> Members.get_member_of_book!(book)
      |> Members.link_book_member_to_user(current_user)
    end

    conn
    |> put_flash(:info, gettext("You have been added to the book"))
    |> redirect(to: ~p"/books/#{book}/transfers")
  end

  defp get_book_by_token(conn, _opts) do
    %{"token" => token} = conn.params

    if book = Books.get_book_by_invitation_token(token) do
      conn |> assign(:token, token) |> assign(:book, book)
    else
      conn
      |> put_flash(:error, gettext("Invitation link is invalid or it has expired"))
      |> redirect(to: ~p"/")
      |> halt()
    end
  end

  defp ensure_user_is_not_member_of_book(conn, _opts) do
    %{book: book, current_user: current_user} = conn.assigns

    if Members.get_membership(book, current_user) do
      conn
      |> put_flash(:info, gettext("You are already member of this book"))
      |> redirect(to: ~p"/books/#{book}/transfers")
      |> halt()
    else
      conn
    end
  end
end
