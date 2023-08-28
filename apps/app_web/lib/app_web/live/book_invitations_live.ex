defmodule AppWeb.BookInvitationsLive do
  @moduledoc """
  The invitation live view.
  List and send new invitations for a book.
  """

  use AppWeb, :live_view

  alias App.Books.BookMember
  alias App.Books.Members

  on_mount {AppWeb.BookAccess, :ensure_book!}
  # TODO Do not allow access to the page if not allowed to invite people

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <.page_header>
      <:title><%= gettext("Invitations") %></:title>
    </.page_header>

    <main class="max-w-prose mx-auto">
      <.heading level={:section} class="mt-6">
        <%= gettext("Invite a new member") %>
      </.heading>

      <.alert :for={{type, message} <- @flash} type={type}><%= message %></.alert>

      <.form
        :let={f}
        for={@changeset}
        id="invite-member"
        class="mx-4"
        phx-change="validate_member"
        phx-submit="invite_member"
      >
        <.input type="text" label={gettext("Nickname")} field={f[:nickname]} required class="w-full" />

        <label>
          <%= gettext("Send invitation to email (optional)") %>
          <input type="email" name="send_to" id="send_to" class="w-full" />
        </label>

        <.button color={:cta} class="mr-4" phx-disable-with={gettext("Sending...")}>
          <%= gettext("Create member") %>
        </.button>
      </.form>
    </main>
    """
  end

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    book = socket.assigns.book

    book_member = %BookMember{book_id: book.id, role: :member}
    changeset = Members.deprecated_change_book_member(book_member)

    socket =
      assign(socket,
        page_title: gettext("Invitations · %{book_name}", book_name: book.name),
        book_member: book_member,
        changeset: changeset
      )

    {:ok, socket}
  end

  @impl Phoenix.LiveView
  def handle_event("validate_member", %{"book_member" => book_member_params}, socket) do
    changeset =
      socket.assigns.book_member
      |> Members.deprecated_change_book_member(book_member_params)
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
         {:ok, email} <- maybe_deliver_invitation(socket, book_member, send_to) do
      changeset = Members.deprecated_change_book_member(socket.assigns.book_member)

      {:noreply,
       socket
       |> put_flash(:info, member_created_flash(email))
       |> assign(changeset: changeset)}
    end
  end

  defp maybe_deliver_invitation(_socket, _book_member, ""), do: {:ok, nil}

  defp maybe_deliver_invitation(socket, book_member, sent_to),
    do: deliver_invitation(socket, book_member, sent_to)

  defp deliver_invitation(socket, book_member, sent_to) do
    Members.deliver_invitation(book_member, sent_to, &url(socket, ~p"/invitation/#{&1}/edit"))
  end

  defp member_created_flash(nil), do: gettext("Member created")
  defp member_created_flash(_email), do: gettext("Invitation sent")
end
