defmodule AppWeb.BookMemberLive do
  @moduledoc """
  The book member index live view.
  Displays the members of a book.
  """

  use AppWeb, :live_view

  alias App.Accounts.Avatars
  alias App.Balance
  alias App.Books
  alias App.Books.Members
  alias App.Books.Rights

  on_mount {AppWeb.BookAccess, :ensure_book!}

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <div class="max-w-prose mx-auto">
      <.tile
        :if={Rights.can_member_invite_new_member?(@current_member)}
        navigate={~p"/books/#{@book}/invite"}
      >
        <.icon name="person-add" />
        <%= gettext("Invite a new member") %>
      </.tile>

      <.member_tile :for={member <- @linked_members} member={member} />

      <.heading :if={not Enum.empty?(@independent_members)} level={:section} class="mt-6">
        <%= gettext("Pending members") %>
      </.heading>

      <.member_tile :for={member <- @independent_members} member={member} />
    </div>
    """
  end

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    book = socket.assigns.book

    members =
      book
      |> Members.list_members_of_book()
      |> Balance.fill_members_balance()

    {independent_members, linked_members} = Enum.split_with(members, &Members.independent?/1)

    socket =
      assign(socket,
        page_title: book.name,
        layout_heading: gettext("Details"),
        linked_members: linked_members,
        independent_members: independent_members
      )

    {:ok, socket, layout: {AppWeb.Layouts, :book}}
  end

  @impl Phoenix.LiveView
  def handle_event("delete", _params, socket) do
    # TODO Handle errors (e.g. if the user is not allowed to delete the book)
    {:ok, _} = Books.delete_book(socket.assigns.book, socket.assigns.current_user)

    {:noreply,
     socket
     |> put_flash(:info, gettext("Book deleted successfully"))
     |> push_navigate(to: ~p"/books")}
  end

  defp member_tile(assigns) do
    ~H"""
    <.tile collapse>
      <.avatar src={Avatars.avatar_url(@member)} alt="" />
      <span class="grow font-bold">
        <%= @member.display_name %>
      </span>
      <%= if has_balance_error?(@member) do %>
        <span class="font-bold text-gray-60">
          XX.xx
        </span>
      <% else %>
        <span class={["font-bold", class_for_member_balance(@member.balance)]}>
          <%= @member.balance %>
        </span>
      <% end %>

      <:description>
        <.alert :if={has_balance_error?(@member)} type="error">
          <%= gettext("The member balance could not be computed") %>
        </.alert>
        <div class="flex justify-between">
          <%= format_role(@member.role) %>
          <span>
            <.member_status member={@member} />
          </span>
        </div>
      </:description>
    </.tile>
    """
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

  defp member_status(assigns) do
    if Members.independent?(assigns.member) do
      ~H"""
      <%= gettext("Invitation sent") %>
      <.icon name="pending" />
      """
    else
      ~H"""
      <%= gettext("Joined") %>
      <.icon name="check" />
      """
    end
  end
end