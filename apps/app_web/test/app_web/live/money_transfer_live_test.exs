defmodule AppWeb.MoneyTransferLiveTest do
  use AppWeb.ConnCase

  import Phoenix.LiveViewTest
  import App.BooksFixtures
  import App.Books.MembersFixtures
  import App.TransfersFixtures

  @create_attrs %{
    label: "Created transfer",
    amount: "10.60",
    type: "payment",
    date: "2022-04-08",
    balance_means_code: "divide_equally"
  }
  @update_attrs %{
    label: "Updated transfer",
    amount: "6.70",
    type: "reimbursement",
    date: "2022-04-10",
    balance_means_code: "weight_by_income"
  }
  @invalid_attrs %{
    label: nil,
    amount: "-10.10",
    type: "income",
    date: "08/04/2022",
    balance_means_code: "divide_equally"
  }

  describe "Index" do
    setup [:register_and_log_in_user, :book_with_member_context]

    test "lists book money transfers", %{conn: conn, book: book, member: member} do
      money_transfer = money_transfer_fixture(book_id: book.id, tenant_id: member.id)

      other_book = book_fixture()

      other_money_transfer =
        money_transfer_fixture(%{
          book_id: other_book.id,
          tenant_id: member.id,
          label: "Other book money transfer"
        })

      {:ok, _index_live, html} = live(conn, Routes.money_transfer_index_path(conn, :index, book))

      assert html =~ "Transfers"
      assert html =~ money_transfer.label
      refute html =~ other_money_transfer.label
    end
  end

  describe "Form" do
    setup [
      :register_and_log_in_user,
      :book_with_member_context,
      :money_transfer_in_book_context
    ]

    test "displays money transfer", %{conn: conn, book: book, money_transfer: money_transfer} do
      {:ok, _form_live, html} =
        live(conn, Routes.money_transfer_form_path(conn, :edit, book, money_transfer))

      assert html =~ "Transfer"
      assert html =~ "<form"
    end

    test "saves new money_transfer", %{conn: conn, book: book} do
      {:ok, form_live, _html} = live(conn, Routes.money_transfer_form_path(conn, :new, book))

      assert form_live
             |> form("#money-transfer-form", money_transfer: @invalid_attrs)
             |> render_change() =~ "is invalid"

      {:ok, _, html} =
        form_live
        |> form("#money-transfer-form", money_transfer: @create_attrs)
        |> render_submit()
        |> follow_redirect(conn, Routes.money_transfer_index_path(conn, :index, book))

      assert html =~ "Money transfer created successfully"
    end

    test "updates money transfer", %{conn: conn, book: book, money_transfer: money_transfer} do
      {:ok, form_live, _html} =
        live(conn, Routes.money_transfer_form_path(conn, :edit, book, money_transfer))

      assert form_live
             |> form("#money-transfer-form", money_transfer: @invalid_attrs)
             |> render_change() =~ "is invalid"

      {:ok, _, html} =
        form_live
        |> form("#money-transfer-form", money_transfer: @update_attrs)
        |> render_submit()
        |> follow_redirect(conn, Routes.money_transfer_index_path(conn, :index, book))

      assert html =~ "Money transfer updated successfully"
    end

    test "deletes money transfer", %{conn: conn, book: book, money_transfer: money_transfer} do
      {:ok, form_live, _html} =
        live(conn, Routes.money_transfer_form_path(conn, :edit, book, money_transfer))

      {:ok, _, html} =
        form_live
        |> element("#delete-money-transfer", "Delete")
        |> render_click()
        |> follow_redirect(conn, Routes.money_transfer_index_path(conn, :index, book))

      assert html =~ "Transfer deleted successfully"
    end
  end

  # Depends on :register_and_log_in_user
  defp book_with_member_context(%{user: user} = context) do
    book = book_fixture()
    member = book_member_fixture(book, user, role: :creator)

    Map.merge(context, %{
      book: book,
      member: member
    })
  end

  # Depends on :book_with_member_context
  defp money_transfer_in_book_context(%{book: book, member: member} = context) do
    Map.put(
      context,
      :money_transfer,
      money_transfer_fixture(book_id: book.id, tenant_id: member.id)
    )
  end
end
