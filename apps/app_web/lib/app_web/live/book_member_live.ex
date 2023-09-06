defmodule AppWeb.BookMemberLive do
  @moduledoc """
  The live view for the book member form.
  Displays information about a book member.
  """
  use AppWeb, :live_view

  alias App.Accounts.Avatars
  alias App.Balance
  alias App.Books.Members

  on_mount {AppWeb.BookAccess, :ensure_book!}
  on_mount {AppWeb.BookAccess, :ensure_book_member!}

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <.page_header>
      <:title><%= @book.name %></:title>
    </.page_header>

    <main class="max-w-prose mx-auto">
      <.alert :for={{type, message} when type in ["error", "info"] <- @flash} type={type}>
        <%= message %>
      </.alert>

      <div class="flex items-center gap-4 mx-4 mb-4">
        <.member_avatar book_member={@book_member} />
        <address class="not-italic">
          <span class="font-bold"><%= @book_member.display_name %></span>
          <%= if has_user?(@book_member) do %>
            <span>(<%= @book_member.nickname %>)</span>
            <div><%= @book_member.email %></div>
          <% end %>
        </address>
        <.member_balance book_member={@book_member} />
      </div>

      <.alert :if={Balance.has_balance_error?(@book_member)} type="error">
        <%= gettext("The member balance could not be computed") %>
      </.alert>

      <div class="mx-4 mb-4">
        <.icon name="calendar-month" />
        <time datetime={@book_member.inserted_at}>
          <%= gettext("Created on %{date}", date: format_date(@book_member.inserted_at)) %>
        </time>
      </div>

      <div class="flex gap-4 mx-4">
        <.button
          color={:feature}
          class="min-w-[5rem]"
          navigate={~p"/books/#{@book}/members/#{@book_member}/edit"}
        >
          <%= gettext("Edit") %>
        </.button>
      </div>
    </main>
    """
  end

  # TODO similar to the one in book_members_live.ex, merge
  defp member_avatar(assigns) do
    ~H"""
    <%= if has_user?(@book_member) do %>
      <.avatar src={Avatars.avatar_url(@book_member)} alt={gettext("The member's avatar")} size={:lg} />
    <% else %>
      <.icon size={:lg} name="person_off" class="m-2" />
    <% end %>
    """
  end

  # TODO similar to the one in book_members_live.ex, merge
  defp member_balance(assigns) do
    ~H"""
    <%= if Balance.has_balance_error?(@book_member) do %>
      <span class="ml-auto font-bold text-gray-60">
        XX.xx
      </span>
    <% else %>
      <span class={["ml-auto font-bold", class_for_member_balance(@book_member.balance)]}>
        <%= @book_member.balance %>
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
    %{book: book, book_member: book_member} = socket.assigns

    # FIXME expensive, cache members balance ?
    book_member =
      book
      |> Members.list_members_of_book()
      |> Balance.fill_members_balance()
      |> Enum.find(&(&1.id == book_member.id))

    {:ok,
     assign(socket,
       book_member: book_member,
       page_title:
         gettext("%{member_name} in %{book_name}",
           member_name: book_member.display_name,
           book_name: book.name
         )
     )}
  end

  defp has_user?(book_member) do
    book_member.user_id != nil
  end
end
