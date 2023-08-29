defmodule AppWeb.BookInvitationsLive do
  @moduledoc """
  The invitation live view.
  Provide the invitation link of the book.
  """
  use AppWeb, :live_view

  alias App.Books

  on_mount {AppWeb.BookAccess, :ensure_book!}

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <.page_header>
      <:title><%= @book.name %></:title>
    </.page_header>

    <main class="max-w-prose mx-auto text-center mt-32">
      <span class="font-bold"><%= gettext("Invite people to join") %></span>
      <.input
        type="text"
        name="invitation_url"
        value={@invitation_url}
        label_class="mb-0"
        class="inline w-80 text-center"
        readonly
        phx-click={JS.dispatch("app:copy-to-clipboard", detail: %{field: "value"})}
      />
      <.alert type="info" class="w-80 mx-auto" id="copied-to-clipboard" hidden>
        <%= gettext("Copied to clipboard") %>
      </.alert>
      <%= gettext("Share this link so people can join your book") %>
    </main>
    """
  end

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    book = socket.assigns.book
    invitation_token = Books.get_book_invitation_token(book)

    socket =
      assign(socket,
        page_title: gettext("Invitations · %{book_name}", book_name: book.name),
        invitation_url: url(~p"/invitations/#{invitation_token}")
      )

    {:ok, socket}
  end
end
