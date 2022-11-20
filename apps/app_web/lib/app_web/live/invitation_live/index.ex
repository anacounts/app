defmodule AppWeb.InvitationLive.Index do
  @moduledoc """
  The invitation live view.
  List and send new invitations for a book.
  """

  use AppWeb, :live_view

  alias App.Auth.Avatars
  alias App.Books.Members

  on_mount {AppWeb.BookAccess, :ensure_book!}

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    book = socket.assigns.book
    members = Members.list_members_of_book(book)

    socket =
      assign(socket,
        page_title: gettext("Invitations · %{book_name}", book_name: book.name),
        members: members
      )

    {:ok, socket}
  end

  @impl Phoenix.LiveView
  def handle_event("invite", %{"email" => email}, socket) do
    book = socket.assigns.book

    # TODO Handle errors (e.g. invited user is already a member)
    # TODO Do not allow access to the page if not allowed to invite people
    {:ok, member} = Members.invite_new_member(book.id, socket.assigns.current_user, email)

    {:noreply,
     socket
     |> put_flash(:info, gettext("Invitation sent successfully"))
     |> update(:members, &[member | &1])}
  end
end
