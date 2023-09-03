defmodule App.Books.BookMemberTest do
  use App.DataCase, async: true

  import App.BooksFixtures
  import App.Books.MembersFixtures

  alias App.Books.BookMember

  setup do
    %{book: book_fixture()}
  end

  describe "deprecated_changeset/2" do
    test "does not change the `:book_id`", %{book: book} do
      book_member = book_member_fixture(book)
      changeset = BookMember.deprecated_changeset(book_member, %{book_id: 1})

      assert changeset.valid?
      assert changeset.changes == %{}
    end

    test "does not change the `:balance_config_id`", %{book: book} do
      book_member = book_member_fixture(book)
      changeset = BookMember.deprecated_changeset(book_member, %{balance_config_id: 1})

      assert changeset.valid?
      assert changeset.changes == %{}
    end
  end
end
