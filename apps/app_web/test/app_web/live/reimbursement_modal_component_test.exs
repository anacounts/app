defmodule AppWeb.ReimbursementModalComponentTest do
  use AppWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import App.BooksFixtures
  import App.Books.MembersFixtures

  setup [:register_and_log_in_user, :book_with_member_context]

  test "displays transaction reimbursement", %{book: book} do
    member1 = book_member_fixture(book, nickname: "Member 1")
    member2 = book_member_fixture(book, nickname: "Member 2")

    html =
      render_component(AppWeb.ReimbursementModalComponent, %{
        id: "reimbursement-modal",
        book: book,
        open: true,
        transaction: %{
          id: "transaction-id",
          from: member1,
          to: member2,
          amount: Money.new!(:EUR, 10)
        }
      })

    assert html =~ "New reimbursement"
    assert html =~ "value=\"Reimbursement from Member 1 to Member 2\""
    assert html =~ "value=\"#{member1.id}\""
    assert html =~ "value=\"#{member2.id}\""
    assert html =~ "value=\"10.00\""
  end

  # Depends on :register_and_log_in_user
  defp book_with_member_context(%{user: user} = context) do
    book = book_fixture()
    member = book_member_fixture(book, user_id: user.id, role: :creator)

    Map.merge(context, %{
      book: book,
      member: member
    })
  end
end
