defmodule AppWeb.InvitationLive.Index do
  @moduledoc """
  The invitation live view.
  List and send new invitations for a book.
  """

  use AppWeb, :live_view

  alias App.Auth.Avatars
  alias App.Books
  alias App.Books.Members

  on_mount {AppWeb.BookAccess, :ensure_book!}

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    %{book: book, current_user: current_user} = socket.assigns
    invitations_suggestions = Books.invitations_suggestions(book, current_user)

    socket =
      assign(socket,
        page_title: gettext("Invitations · %{book_name}", book_name: book.name),
        invitations_suggestions: invitations_suggestions
      )

    {:ok, socket, temporary_assigns: [invitations_suggestions: []]}
  end

  @impl Phoenix.LiveView
  def handle_event("invite_email", %{"email" => email}, socket) do
    %{book: book, current_user: current_user} = socket.assigns

    # TODO Handle errors (e.g. invited user is already a member)
    # TODO Do not allow access to the page if not allowed to invite people
    {:ok, _member} = Members.invite_new_member(book.id, current_user, email)

    {:noreply,
     socket
     |> assign(invitations_suggestions: Books.invitations_suggestions(book, current_user))
     |> put_flash(:info, gettext("Invitation sent successfully"))}
  end
end
