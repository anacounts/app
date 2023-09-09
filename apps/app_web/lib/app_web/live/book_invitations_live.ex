defmodule AppWeb.BookInvitationsLive do
  @moduledoc """
  The invitation live view.
  Provide the invitation link of the book.
  """
  use AppWeb, :live_view

  alias App.Books

  on_mount {AppWeb.BookAccess, :ensure_book!}
  on_mount {AppWeb.BookAccess, :ensure_open_book!}

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <.page_header>
      <:title><%= @book.name %></:title>
    </.page_header>

    <main class="max-w-prose mx-auto mt-32">
      <div class="text-center">
        <span class="font-bold"><%= gettext("Invite people to join") %></span>
        <.input
          type="text"
          name="invitation_url"
          value={@invitation_url}
          label_class="mb-0"
          class="inline w-80 text-center"
          readonly
          phx-click={JS.dispatch("app:copy-to-clipboard") |> show("#copied-to-clipboard")}
        />
        <%= gettext("Share this link so people can join your book") %>
      </div>
      <.flash kind={:info} title={gettext("Success!")} id="copied-to-clipboard" hidden>
        <%= gettext("Copied to clipboard") %>
      </.flash>
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
