defmodule AppWeb.BookMembersLive do
  @moduledoc """
  The book member index live view.
  Displays the members of a book.
  """

  use AppWeb, :live_view

  alias App.Accounts.Avatars
  alias App.Balance
  alias App.Books

  alias AppWeb.BooksHelpers

  on_mount {AppWeb.BookAccess, :ensure_book!}
  on_mount {AppWeb.BookAccess, :assign_book_members}
  on_mount {AppWeb.BookAccess, :assign_book_unbalanced}

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <div class="max-w-prose mx-auto">
      <div :if={not Books.closed?(@book)} class="grid grid-cols-2">
        <.tile navigate={~p"/books/#{@book}/invite"} summary_class="justify-center">
          <.icon name="mail" />
          <%= gettext("Invite people") %>
        </.tile>
        <.tile navigate={~p"/books/#{@book}/members/new"} summary_class="justify-center">
          <.icon name="person-add" />
          <%= gettext("Create manually") %>
        </.tile>
      </div>

      <.tile :for={member <- @book_members} navigate={~p"/books/#{@book}/members/#{member}"}>
        <.member_avatar member={member} />
        <span class="grow font-bold">
          <%= member.display_name %>
        </span>
        <.member_balance member={member} />
      </.tile>
    </div>
    """
  end

  defp member_avatar(assigns) do
    if has_user?(assigns.member) do
      ~H"""
      <.avatar src={Avatars.avatar_url(@member)} alt="" />
      """
    else
      ~H"""
      <.icon size={:lg} name="person_off" class="mx-1" />
      """
    end
  end

  defp has_user?(book_member) do
    book_member.user_id != nil
  end

  defp member_balance(assigns) do
    ~H"""
    <%= if Balance.has_balance_error?(@member) do %>
      <span class="font-bold text-gray-60">
        XX.xx
      </span>
    <% else %>
      <span class={["font-bold", class_for_member_balance(@member.balance)]}>
        <%= @member.balance %>
      </span>
    <% end %>
    """
  end

  defp class_for_member_balance(balance) do
    cond do
      Money.zero?(balance) -> nil
      Money.negative?(balance) -> "text-error"
      true -> "text-info"
    end
  end

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    book = socket.assigns.book

    socket = assign(socket, page_title: book.name)

    {:ok, socket, layout: {AppWeb.Layouts, :book}}
  end

  @impl Phoenix.LiveView
  def handle_event("delete-book", _params, socket) do
    BooksHelpers.handle_delete_book(socket)
  end

  def handle_event("close-book", _params, socket) do
    BooksHelpers.handle_close_book(socket)
  end

  def handle_event("reopen-book", _params, socket) do
    BooksHelpers.handle_reopen_book(socket)
  end
end
