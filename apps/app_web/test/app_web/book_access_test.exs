defmodule AppWeb.BookAccessTest do
  use AppWeb.ConnCase, async: true

  import App.BooksFixtures
  import App.Books.MembersFixtures
  import App.TransfersFixtures

  alias App.Balance

  alias AppWeb.BookAccess

  alias Phoenix.LiveView

  setup :register_and_log_in_user

  setup %{user: user} do
    socket =
      %LiveView.Socket{}
      |> Phoenix.Component.assign(:current_user, user)

    %{socket: socket}
  end

  describe "on_mount: ensure_book!" do
    test "assigns the book found in parameters", %{socket: socket, user: user} do
      book = book_fixture()
      member = book_member_fixture(book, user_id: user.id, role: :creator)

      {:cont, updated_socket} =
        BookAccess.on_mount(:ensure_book!, %{"book_id" => book.id}, nil, socket)

      assert updated_socket.assigns.book.id == book.id
      assert updated_socket.assigns.current_member.id == member.id
    end

    test "raises if the user does not have access to the book", %{socket: socket} do
      book = book_fixture()

      assert_raise Ecto.NoResultsError, fn ->
        BookAccess.on_mount(:ensure_book!, %{"book_id" => book.id}, nil, socket)
      end
    end

    test "raises if the book is not found", %{socket: socket} do
      assert_raise Ecto.NoResultsError, fn ->
        BookAccess.on_mount(:ensure_book!, %{"book_id" => 0}, nil, socket)
      end
    end
  end

  describe "on_mount: assign_book_members" do
    test "assigns the book members of the book assign", %{socket: socket} do
      book = book_fixture()
      member = book_member_fixture(book)

      socket = Phoenix.Component.assign(socket, :book, book)

      {:cont, updated_socket} =
        BookAccess.on_mount(:assign_book_members, nil, nil, socket)

      assert Enum.map(updated_socket.assigns.book_members, & &1.id) == [member.id]
    end
  end

  describe "on_mount: assign_book_unbalanced" do
    test "assigns book_unbalanced? == true if the book isn't balanced", %{socket: socket} do
      book = book_fixture()
      member1 = book_member_fixture(book)
      member2 = book_member_fixture(book)

      _transfer =
        deprecated_money_transfer_fixture(book,
          amount: Money.new!(:EUR, 1000),
          tenant_id: member1.id,
          peers: [%{member_id: member1.id}, %{member_id: member2.id}]
        )

      members = Balance.fill_members_balance([member1, member2])
      socket = Phoenix.Component.assign(socket, book: book, book_members: members)

      {:cont, updated_socket} =
        BookAccess.on_mount(:assign_book_unbalanced, nil, nil, socket)

      assert updated_socket.assigns.book_unbalanced?
    end

    test "assigns book_unbalanced? == false if the book is balanced", %{socket: socket} do
      book = book_fixture()
      member1 = book_member_fixture(book)
      member2 = book_member_fixture(book)

      members = Balance.fill_members_balance([member1, member2])
      socket = Phoenix.Component.assign(socket, book: book, book_members: members)

      {:cont, updated_socket} =
        BookAccess.on_mount(:assign_book_unbalanced, nil, nil, socket)

      refute updated_socket.assigns.book_unbalanced?
    end
  end

  describe "on_mount: ensure_book_member!" do
    setup %{socket: socket} do
      book = book_fixture()

      socket =
        socket
        |> Phoenix.Component.assign(:book, book)

      %{socket: socket, book: book}
    end

    test "assigns the book member found in parameters", %{socket: socket, book: book} do
      book_member = book_member_fixture(book)

      {:cont, updated_socket} =
        BookAccess.on_mount(
          :ensure_book_member!,
          %{"book_member_id" => book_member.id},
          nil,
          socket
        )

      assert updated_socket.assigns.book_member.id == book_member.id
    end

    test "raises if the member is not part of the book", %{socket: socket} do
      book_member = book_member_fixture(book_fixture())

      assert_raise Ecto.NoResultsError, fn ->
        BookAccess.on_mount(
          :ensure_book_member!,
          %{"book_member_id" => book_member.id},
          nil,
          socket
        )
      end
    end

    test "raises if the member does not exist", %{socket: socket} do
      assert_raise Ecto.NoResultsError, fn ->
        BookAccess.on_mount(:ensure_book_member!, %{"book_member_id" => 0}, nil, socket)
      end
    end
  end
end
