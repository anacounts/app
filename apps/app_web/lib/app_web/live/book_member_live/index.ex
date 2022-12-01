defmodule AppWeb.BookMemberLive.Index do
  @moduledoc """
  The book member index live view.
  Displays the members of a book.
  """

  use AppWeb, :live_view

  alias App.Auth.Avatars
  alias App.Balance
  alias App.Books
  alias App.Books.Members
  alias App.Books.Rights

  on_mount {AppWeb.BookAccess, :ensure_book!}

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    book = socket.assigns.book

    confirmed_members =
      book
      |> Members.list_confirmed_members_of_book()
      |> Balance.fill_members_balance()

    pending_members = Members.list_pending_members_of_book(book)

    socket =
      assign(socket,
        page_title: book.name,
        layout_heading: gettext("Details"),
        confirmed_members: confirmed_members,
        pending_members: pending_members
      )

    {:ok, socket, layout: {AppWeb.LayoutView, "book.html"}}
  end

  @impl Phoenix.LiveView
  def handle_event("delete", _params, socket) do
    # TODO Handle errors (e.g. if the user is not allowed to delete the book)
    {:ok, _} = Books.delete_book(socket.assigns.book, socket.assigns.current_user)

    {:noreply,
     socket
     |> put_flash(:info, gettext("Book deleted successfully"))
     |> push_navigate(to: Routes.book_index_path(socket, :index))}
  end

  defp format_role(:creator), do: gettext("Creator")
  defp format_role(:member), do: gettext("Member")
  defp format_role(:viewer), do: gettext("Viewer")

  defp has_balance_error?(member) do
    match?({:error, _reasons}, member.balance)
  end

  defp class_for_member_balance(balance) do
    cond do
      Money.zero?(balance) -> nil
      Money.negative?(balance) -> "text-error"
      true -> "text-info"
    end
  end
end
