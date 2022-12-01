defmodule App.Books.MembersTest do
  use App.DataCase, async: true

  import App.AuthFixtures
  import App.BooksFixtures
  import App.Books.MembersFixtures

  alias App.Books.BookMember
  alias App.Books.InvitationToken
  alias App.Books.Members

  describe "list_members_of_book/1" do
    test "lists all members of a book" do
      book = book_fixture()
      confirmed_member = book_member_fixture(book, user_id: user_fixture().id)
      pending_member = book_member_fixture(book, user_id: nil)
      _other_member = book_member_fixture(book_fixture())

      assert book
             |> Members.list_members_of_book()
             |> Enum.map(& &1.id)
             |> Enum.sort() == [confirmed_member.id, pending_member.id]
    end
  end

  describe "list_confirmed_members_of_book/1" do
    test "lists members of a book that have been confirmed" do
      book = book_fixture()
      confirmed_member = book_member_fixture(book, user_id: user_fixture().id)
      _pending_member = book_member_fixture(book, user_id: nil)
      _other_member = book_member_fixture(book_fixture())

      assert book
             |> Members.list_confirmed_members_of_book()
             |> Enum.map(& &1.id) == [confirmed_member.id]
    end
  end

  describe "list_pending_members_of_book/1" do
    test "lists members of a book that have not been confirmed yet" do
      book = book_fixture()
      _confirmed_member = book_member_fixture(book, user_id: user_fixture().id)
      pending_member = book_member_fixture(book, user_id: nil)
      _other_member = book_member_fixture(book_fixture())

      assert book
             |> Members.list_pending_members_of_book()
             |> Enum.map(& &1.id) == [pending_member.id]
    end
  end

  describe "get_book_member!/1" do
    setup :book_with_creator_context

    test "returns the book_member with given id", %{book: book} do
      other_user = user_fixture()
      book_member = book_member_fixture(book, user_id: other_user.id)

      result = Members.get_book_member!(book_member.id)
      assert result.id == book_member.id
      assert result.book_id == book_member.book_id
      assert result.user_id == book_member.user_id
    end

    test "raises if the book_member does not exist" do
      assert_raise Ecto.NoResultsError, fn ->
        Members.get_book_member!(-1)
      end
    end
  end

  describe "invite_member/2" do
    setup :book_with_creator_context

    test "adds a member to the book", %{book: book, user: user} do
      invited_user = user_fixture()

      assert {:ok, book_member} = Members.invite_new_member(book.id, user, invited_user.email)

      assert book_member.book_id == book.id
      assert book_member.user_id == invited_user.id
      assert book_member.role == :member
    end

    test "returns an error if the user is not allowed a member of the book", %{book: book} do
      other_user = user_fixture()
      invited_user = user_fixture()

      assert {:error, :unauthorized} =
               Members.invite_new_member(book.id, other_user, invited_user.email)
    end

    test "returns an error if the user is not allowed to invite new members", %{book: book} do
      other_user = user_fixture()
      _other_member = book_member_fixture(book, user_id: other_user.id)

      invited_user = user_fixture()

      assert {:error, :unauthorized} =
               Members.invite_new_member(book.id, other_user, invited_user.email)
    end

    test "fails if the user is already member", %{book: book, user: user} do
      invited_user = user_fixture()

      # Create the first membership
      assert {:ok, _book_member} = Members.invite_new_member(book.id, user, invited_user.email)

      assert {:error, changeset} = Members.invite_new_member(book.id, user, invited_user.email)
      assert errors_on(changeset) == %{user_id: ["user is already a member of this book"]}
    end
  end

  describe "create_book_member/2" do
    setup do
      %{book: book_fixture()}
    end

    test "create a new book member", %{book: book} do
      assert {:ok, _book_member} = Members.create_book_member(book, book_member_attributes(book))
    end

    test "can link to a user", %{book: book} do
      user = user_fixture()

      assert {:ok, book_member} =
               Members.create_book_member(book, book_member_attributes(book, user_id: user.id))

      assert book_member.user_id == user.id
    end

    test "returns an error if given invalid attributes", %{book: book} do
      assert {:error, changeset} =
               Members.create_book_member(book, book_member_attributes(book, role: :invalid))

      assert errors_on(changeset) == %{role: ["is invalid"]}
    end

    test "fails if the user is already a member of the book", %{book: book} do
      user = user_fixture()
      book_member_fixture(book, user_id: user.id)

      assert {:error, changeset} =
               Members.create_book_member(book, book_member_attributes(book, user_id: user.id))

      assert errors_on(changeset) == %{user_id: ["user is already a member of this book"]}
    end
  end

  describe "deliver_invitation/3" do
    setup do
      book_member = book_member_fixture(book_fixture())

      %{
        book_member: book_member,
        email: unique_user_email()
      }
    end

    test "send token through email", %{book_member: book_member, email: email} do
      token =
        extract_invitation_token(fn url ->
          Members.deliver_invitation(book_member, email, url)
        end)

      {:ok, decoded_token} = Base.url_decode64(token, padding: false)

      assert user_token =
               Repo.get_by(InvitationToken, token: :crypto.hash(:sha256, decoded_token))

      assert user_token.book_member_id == book_member.id
      assert user_token.sent_to == email
    end
  end

  describe "accept_invitation/2" do
    setup do
      book_member = book_member_fixture(book_fixture())
      email = unique_user_email()

      token =
        extract_user_token(fn url ->
          Members.deliver_invitation(book_member, email, url)
        end)

      %{book_member: book_member, email: email, token: token}
    end

    test "updates the member found by the token", %{
      book_member: book_member,
      email: email,
      token: token
    } do
      user = %{user_fixture() | email: email}

      assert {:ok, found_member} = Members.accept_invitation(token, user)

      assert found_member.id == book_member.id
      assert found_member.user_id == user.id
    end

    test "does not update member with invalid token", %{} do
      user = user_fixture()

      assert {:error, :invalid_token} = Members.accept_invitation("invalid-token", user)
    end

    test "does not update member if user email changed", %{book_member: book_member, token: token} do
      user = user_fixture()

      assert {:error, :invalid_token} =
               Members.accept_invitation(token, %{user | email: "current@example.com"})

      refute Repo.get!(BookMember, book_member.id).user_id
    end
  end

  defp book_with_creator_context(_context) do
    book = book_fixture()
    user = user_fixture()
    member = book_member_fixture(book, user_id: user.id, role: :creator)

    %{
      book: book,
      user: user,
      member: member
    }
  end
end
