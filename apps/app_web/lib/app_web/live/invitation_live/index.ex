defmodule AppWeb.InvitationLive.Index do
  @moduledoc """
  The invitation live view.
  List and send new invitations for a book.
  """

  use AppWeb, :live_view

  alias App.Auth.Avatars
  alias App.Books
  alias App.Books.Members

  @impl Phoenix.LiveView
  def mount(%{"book_id" => book_id}, _session, socket) do
    book =
      Books.get_book_of_user!(book_id, socket.assigns.current_user)
      |> App.Repo.preload(members: :user)

    socket =
      assign(socket,
        page_title: gettext("Invitations · %{book_name}", book_name: book.name),
        book: book
      )

    {:ok, socket}
  end

  @impl Phoenix.LiveView
  def handle_event("invite", %{"email" => email}, socket) do
    book = socket.assigns.book

    Members.invite_new_member(book.id, email)

    {:noreply, put_flash(socket, :info, gettext("Invitation sent successfully"))}
  end
end
