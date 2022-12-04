defmodule AppWeb.InvitationLive.Index do
  @moduledoc """
  The invitation live view.
  List and send new invitations for a book.
  """

  use AppWeb, :live_view

  alias App.Auth
  alias App.Auth.Avatars
  alias App.Books
  alias App.Books.BookMember
  alias App.Books.Members

  on_mount {AppWeb.BookAccess, :ensure_book!}
  # TODO Do not allow access to the page if not allowed to invite people

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    %{book: book, current_user: current_user} = socket.assigns

    book_member = %BookMember{book_id: book.id, role: :member}
    changeset = Members.change_book_member(book_member)
    invitations_suggestions = Books.invitations_suggestions(book, current_user)

    socket =
      assign(socket,
        page_title: gettext("Invitations · %{book_name}", book_name: book.name),
        book_member: book_member,
        changeset: changeset,
        invitations_suggestions: invitations_suggestions
      )

    {:ok, socket, temporary_assigns: [invitations_suggestions: []]}
  end

  @impl Phoenix.LiveView
  def handle_event("validate_member", %{"book_member" => book_member_params}, socket) do
    changeset =
      socket.assigns.book_member
      |> Members.change_book_member(book_member_params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, :changeset, changeset)}
  end

  def handle_event(
        "invite_member",
        %{"book_member" => book_member_params, "send_to" => send_to},
        socket
      ) do
    member_params_with_default = Map.put(book_member_params, "role", "member")

    with {:ok, book_member} <-
           Members.create_book_member(socket.assigns.book, member_params_with_default),
         {:ok, email} <- maybe_deliver_invitation(book_member, send_to) do
      changeset = Members.change_book_member(socket.assigns.book_member)

      {:noreply,
       socket
       |> put_flash(:info, member_added_flash(email))
       |> assign(changeset: changeset)}
    end
  end

  def handle_event("invite_user", %{"id" => id}, socket) do
    book = socket.assigns.book
    user = Auth.get_user!(id)

    with {:ok, book_member} <-
           Members.create_book_member(socket.assigns.book, %{
             nickname: user.display_name,
             role: :member
           }),
         {:ok, _email} <- deliver_invitation(book_member, user.email) do
      {:noreply,
       socket
       |> assign(
         invitations_suggestions: Books.invitations_suggestions(book, socket.assigns.current_user)
       )
       |> put_flash(:info, gettext("Invitation sent"))}
    end
  end

  defp maybe_deliver_invitation(_book_member, ""), do: {:ok, nil}

  defp maybe_deliver_invitation(book_member, sent_to),
    do: deliver_invitation(book_member, sent_to)

  defp deliver_invitation(book_member, sent_to) do
    Members.deliver_invitation(
      book_member,
      sent_to,
      &Routes.book_invitation_url(AppWeb.Endpoint, :edit, &1)
    )
  end

  defp member_added_flash(nil), do: gettext("Member added")
  defp member_added_flash(_email), do: gettext("Invitation sent")
end
