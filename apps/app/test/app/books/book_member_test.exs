defmodule App.Books.BookMemberTest do
  use App.DataCase, async: true

  import App.BooksFixtures
  import App.Books.MembersFixtures

  alias App.Books.BookMember

  setup do
    %{book: book_fixture()}
  end

  describe "changeset/2" do
    test "does not change the `:book_id`", %{book: book} do
      book_member = book_member_fixture(book)
      changeset = BookMember.changeset(book_member, %{book_id: 1})

      assert changeset.valid?
      assert changeset.changes == %{}
    end

    test "does not change the `:balance_config_id`", %{book: book} do
      book_member = book_member_fixture(book)
      changeset = BookMember.changeset(book_member, %{balance_config_id: 1})

      assert changeset.valid?
      assert changeset.changes == %{}
    end
  end

  describe "balance_config_changeset/2" do
    test "changes the `:balance_config_id`", %{book: book} do
      book_member = book_member_fixture(book)
      changeset = BookMember.balance_config_changeset(book_member, %{balance_config_id: 1})

      assert changeset.valid?
      assert changeset.changes == %{balance_config_id: 1}
    end

    test "does not change other fields", %{book: book} do
      book_member = book_member_fixture(book)

      changeset =
        BookMember.balance_config_changeset(book_member, %{
          book_id: 1,
          user_id: 1,
          role: :viewer,
          nickname: "New nickname"
        })

      assert changeset.valid?
      assert changeset.changes == %{}
    end
  end
end