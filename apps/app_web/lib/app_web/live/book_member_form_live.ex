defmodule AppWeb.BookMemberFormLive do
  @moduledoc """
  The live view for the book member form.
  Create or edit a book member.
  """
  use AppWeb, :live_view

  alias App.Books.BookMember
  alias App.Books.Members

  on_mount {AppWeb.BookAccess, :ensure_book!}
  on_mount {AppWeb.BookAccess, :ensure_open_book!}

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <.page_header>
      <:title>
        <%= if @live_action == :new,
          do: gettext("New Member"),
          else: gettext("Edit Member") %>
      </:title>
    </.page_header>

    <main class="max-w-prose mx-auto">
      <.form for={@form} id="member-form" phx-change="validate" phx-submit="save">
        <section id="details">
          <div class="mx-4 mb-4 md:min-w-[380px]">
            <.input
              type="text"
              label={gettext("Nickname")}
              field={@form[:nickname]}
              class="w-full"
              pattern=".{1,255}"
              required
            />
          </div>

          <div class="mx-4 mb-4">
            <.button color={:cta} class="min-w-[5rem]" phx-disable-with={gettext("Saving...")}>
              <%= gettext("Save") %>
            </.button>
          </div>
        </section>
      </.form>
    </main>
    """
  end

  @impl Phoenix.LiveView
  def mount(params, _session, socket) do
    {:ok, mount_action(socket, socket.assigns.live_action, params)}
  end

  defp mount_action(socket, :new, _params) do
    assign(socket,
      page_title: gettext("New Member"),
      form:
        %BookMember{}
        |> Members.change_book_member()
        |> to_form()
    )
  end

  defp mount_action(socket, :edit, %{"book_member_id" => book_member_id}) do
    book = socket.assigns.book
    member = Members.get_member_of_book!(book_member_id, book)

    assign(socket,
      page_title:
        gettext("Edit %{member_name} · %{book_name}",
          member_name: member.display_name,
          book_name: book.name
        ),
      book_member: member,
      form:
        member
        |> Members.change_book_member()
        |> to_form()
    )
  end

  @impl Phoenix.LiveView
  def handle_event("validate", %{"book_member" => book_member_params}, socket) do
    form =
      %BookMember{}
      |> Members.change_book_member(book_member_params)
      |> Map.put(:action, :validate)
      |> to_form()

    {:noreply, assign(socket, :form, form)}
  end

  def handle_event("save", %{"book_member" => book_member_params}, socket) do
    save_book_member(socket, socket.assigns.live_action, book_member_params)
  end

  defp save_book_member(socket, :new, book_member_params) do
    book = socket.assigns.book

    case Members.create_book_member(book, book_member_params) do
      {:ok, member} ->
        {:noreply,
         socket
         |> put_flash(:info, gettext("Member created successfully"))
         |> push_navigate(to: ~p"/books/#{book}/members/#{member}")}

      {:error, changeset} ->
        {:noreply, assign(socket, :form, to_form(changeset))}
    end
  end

  defp save_book_member(socket, :edit, book_member_params) do
    %{book: book, book_member: member} = socket.assigns

    case Members.update_book_member(member, book_member_params) do
      {:ok, member} ->
        {:noreply,
         socket
         |> put_flash(:info, gettext("Member updated successfully"))
         |> push_navigate(to: ~p"/books/#{book}/members/#{member}")}

      {:error, changeset} ->
        {:noreply, assign(socket, :form, to_form(changeset))}
    end
  end
end
