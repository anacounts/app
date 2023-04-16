defmodule App.Books.MembersTest do
  use App.DataCase, async: true

  import App.AccountsFixtures
  import App.Balance.BalanceConfigsFixtures
  import App.BooksFixtures
  import App.Books.MembersFixtures

  alias App.Balance.BalanceConfig
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

    test "gets the member nickname as `:display_name` if not linked to a user", %{book: book} do
      book_member = book_member_fixture(book, user_id: nil, nickname: "APublicPseudo")

      assert book_member = Members.get_book_member!(book_member.id)
      assert book_member.nickname == "APublicPseudo"
      assert book_member.display_name == "APublicPseudo"
    end

    test "gets the user display_name as `:display_name` if linked to a user", %{book: book} do
      user = user_fixture()
      book_member = book_member_fixture(book, user_id: user.id, nickname: "APublicPseudo")

      assert book_member = Members.get_book_member!(book_member.id)
      assert book_member.nickname == "APublicPseudo"
      assert book_member.display_name == user.display_name
    end

    test "raises if the book_member does not exist" do
      assert_raise Ecto.NoResultsError, fn ->
        Members.get_book_member!(-1)
      end
    end
  end

  describe "get_book_member_by_invitation_token/2" do
    setup :book_with_creator_context

    @valid_invitation_email "email@example.com"

    test "returns the book_member with given invitation token", %{book: book} do
      book_member = book_member_fixture(book)

      {hashed_token, _invitation_token} =
        invitation_token_fixture(book_member, @valid_invitation_email)

      user = user_fixture(email: @valid_invitation_email)

      assert result = Members.get_book_member_by_invitation_token(hashed_token, user)
      assert result.id == book_member.id
      assert result.book_id == book_member.book_id
      assert result.user_id == book_member.user_id
    end

    test "returns nil if the invitation token cannot be found" do
      user = user_fixture()

      refute Base.encode64("notfound")
             |> Members.get_book_member_by_invitation_token(user)
    end

    test "returns nil if the invitation token is invalid" do
      user = user_fixture()
      refute Members.get_book_member_by_invitation_token("invalid", user)
    end

    test "returns nil if user email does not match the token", %{book: book} do
      book_member = book_member_fixture(book)
      {hashed_token, _invitation_token} = invitation_token_fixture(book_member)

      other_user = user_fixture()

      refute Members.get_book_member_by_invitation_token(hashed_token, other_user)
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
      user = user_fixture()

      %{book_member: book_member, user: user}
    end

    test "links the user to the book member", %{book_member: book_member, user: user} do
      assert {:ok, book_member} = Members.accept_invitation(book_member, user)
      assert book_member.user_id == user.id
      assert book_member.balance_config_id == nil
    end

    test "copies the user balance config if they have one", %{
      book_member: book_member,
      user: user
    } do
      user_balance_config = user_balance_config_fixture(user)
      user = Repo.reload(user)

      assert {:ok, book_member} = Members.accept_invitation(book_member, user)
      assert Repo.reload(book_member).balance_config_id == user_balance_config.id
    end

    # TODO
    test "deletes the book member former balance config if it is not used anymore", %{
      book_member: book_member,
      user: user
    } do
      _user_balance_config = user_balance_config_fixture(user)
      user = Repo.reload(user)

      member_balance_config = member_balance_config_fixture(book_member)
      book_member = Repo.reload(book_member)

      assert {:ok, _book_member} = Members.accept_invitation(book_member, user)

      refute Repo.get(BalanceConfig, member_balance_config.id)
    end

    test "does not delete the book member former balance config if it is used by another entity",
         %{
           book_member: book_member,
           user: user
         } do
      _user_balance_config = user_balance_config_fixture(user)
      user = Repo.reload(user)

      member_balance_config = member_balance_config_fixture(book_member)
      book_member = Repo.reload(book_member)

      other_book_member = book_member_fixture(book_fixture())
      member_balance_config_link_fixture(other_book_member, member_balance_config)

      assert {:ok, _book_member} = Members.accept_invitation(book_member, user)

      assert Repo.get(BalanceConfig, member_balance_config.id)
    end

    test "raises if the book member is already linked to a user", %{user: user} do
      other_user = user_fixture()
      book_member = book_member_fixture(book_fixture(), user_id: other_user.id)

      assert_raise FunctionClauseError, fn ->
        Members.accept_invitation(book_member, user)
      end
    end

    test "deletes the invitation token", %{book_member: book_member, user: user} do
      token =
        extract_invitation_token(fn url ->
          Members.deliver_invitation(book_member, user.email, url)
        end)

      assert {:ok, _book_member} = Members.accept_invitation(book_member, user)

      {:ok, decoded_token} = Base.url_decode64(token, padding: false)
      refute Repo.get_by(InvitationToken, token: :crypto.hash(:sha256, decoded_token))
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
