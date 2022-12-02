defmodule AppWeb.BookInvitationController do
  @moduledoc """
  Let users join books by opening invitations.

  This controller is responsible for handling any requests that match
  `/invitation/:token`, where `:token` is the token of the invitation. When an invitation
  is open, first ask the user it they want to join the book. If they do, the member
  linked to the invitation is linked to the user and the invitation is deleted. Otherwise,
  the invitation remains and the user is redirected to their books.
  """

  use AppWeb, :controller

  alias App.Books
  alias App.Books.Members

  plug :get_book_member_by_token
  plug :put_layout, "auth.html"

  def edit(conn, _opts) do
    book_member = conn.assigns.book_member
    book = Books.get_book!(book_member.book_id)

    render(conn, "edit.html",
      page_title: gettext("Join %{book_name}", book_name: book.name),
      book: book
    )
  end

  def update(conn, _opts) do
    %{book_member: book_member, current_user: current_user} = conn.assigns

    {:ok, _book_member} = Members.accept_invitation(book_member, current_user)

    conn
    |> put_flash(:info, gettext("You have been added to the book."))
    |> redirect(to: Routes.money_transfer_index_path(conn, :index, book_member.book_id))
  end

  defp get_book_member_by_token(conn, _opts) do
    %{"token" => token} = conn.params

    if book_member = Members.get_book_member_by_invitation_token(token, conn.assigns.current_user) do
      conn |> assign(:token, token) |> assign(:book_member, book_member)
    else
      conn
      |> put_flash(:error, gettext("Invitation link is invalid or it has expired."))
      |> redirect(to: "/")
      |> halt()
    end
  end
end
