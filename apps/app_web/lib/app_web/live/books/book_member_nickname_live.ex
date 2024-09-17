defmodule AppWeb.BookMemberNicknameLive do
  use AppWeb, :live_view

  alias App.Books.BookMember
  alias App.Books.Members

  on_mount {AppWeb.BookAccess, :ensure_book!}
  on_mount {AppWeb.BookAccess, :ensure_book_member!}

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <.app_page>
      <:breadcrumb>
        <.breadcrumb_ellipsis />
        <.breadcrumb_item navigate={~p"/books/#{@book}/profile"}>
          <%= gettext("My profile") %>
        </.breadcrumb_item>
        <.breadcrumb_item>
          <%= @page_title %>
        </.breadcrumb_item>
      </:breadcrumb>
      <:title><%= @page_title %></:title>

      <.form
        for={@form}
        id="member-nickname-form"
        phx-change="validate"
        phx-submit="submit"
        class="container space-y-2"
      >
        <p class="mb-4">
          <%= gettext("This is your current nickname") %><br />
          <span class="label"><%= @current_member.nickname %></span>
        </p>
        <p><%= gettext("What would you like to change it to?") %></p>
        <.input field={@form[:nickname]} type="text" required phx-debounce />
        <p>
          <%= gettext(
            "This will only change you nickname in the current book." <>
              " You can change your nickname as many times as you want or need to."
          ) %>
        </p>

        <.button_group>
          <.button kind={:primary}>
            <%= gettext("Change nickname") %>
          </.button>
        </.button_group>
      </.form>
    </.app_page>
    """
  end

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    form =
      %BookMember{}
      |> Members.change_book_member_nickname()
      |> to_form()

    socket =
      assign(socket,
        page_title: gettext("Change nickname"),
        form: form
      )

    {:ok, socket}
  end

  @impl Phoenix.LiveView
  def handle_event("validate", %{"book_member" => book_member_params}, socket) do
    form =
      %BookMember{}
      |> Members.change_book_member_nickname(book_member_params)
      |> Map.put(:action, :validate)
      |> to_form()

    {:noreply, assign(socket, :form, form)}
  end

  def handle_event("submit", %{"book_member" => book_member_params}, socket) do
    case Members.update_book_member_nickname(socket.assigns.book_member, book_member_params) do
      {:ok, member} ->
        redirect_path = redirect_path(member, socket.assigns.current_member)

        {:noreply,
         socket
         |> put_flash(:info, gettext("Member updated successfully"))
         |> push_navigate(to: redirect_path)}

      {:error, changeset} ->
        {:noreply, assign(socket, :form, to_form(changeset))}
    end
  end

  # If the edited member is the current member, redirect to their profile
  # Otherwise, redirect to the member's page.
  defp redirect_path(%{id: id} = member, %{id: id} = _current_member) do
    ~p"/books/#{member.book_id}/profile"
  end

  defp redirect_path(member, _current_member) do
    ~p"/books/#{member.book_id}/members/#{member}"
  end
end
