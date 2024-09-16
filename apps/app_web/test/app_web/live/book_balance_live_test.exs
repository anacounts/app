defmodule AppWeb.BookBalanceLiveTest do
  use AppWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import App.Books.MembersFixtures
  import App.BooksFixtures
  import App.TransfersFixtures

  alias App.Repo

  alias App.Books

  setup [:register_and_log_in_user, :book_with_member_context]

  # Create a money transfer with two peers, making the book imbalanced
  setup %{book: book} = context do
    member1 = book_member_fixture(book)
    member2 = book_member_fixture(book)

    Map.merge(context, %{
      money_transfer:
        deprecated_money_transfer_fixture(book,
          tenant_id: member1.id,
          peers: [%{member_id: member1.id}, %{member_id: member2.id}],
          amount: Money.new!(:EUR, 10)
        ),
      peer_member1: member1,
      peer_member2: member2
    })
  end

  test "balance tab is highlighted", %{conn: conn, book: book} do
    {:ok, _live, html} = live(conn, ~p"/books/#{book}/balance")

    assert [class] =
             Floki.attribute(html, ~s(.tabs__link[href="#{~p"/books/#{book}/balance"}"]), "class")

    assert String.contains?(class, "tabs__link--active")
  end

  test "deletes book", %{conn: conn, book: book} do
    {:ok, show_live, _html} = live(conn, ~p"/books/#{book}/balance")

    assert {:ok, _, html} =
             show_live
             |> element("#delete-book", "Delete")
             |> render_click()
             |> follow_redirect(conn, ~p"/books")

    refute html =~ book.name
  end

  test "closes book", %{conn: conn, book: book} do
    {:ok, live, _html} = live(conn, ~p"/books/#{book}/balance")

    assert html =
             live
             |> element("#close-book", "Close")
             |> render_click()

    assert html =~ "Book closed successfully"
    assert book |> Repo.reload() |> Books.closed?()
  end

  test "reopens book", %{conn: conn, book: book} do
    book = Books.close_book!(book)

    {:ok, live, _html} = live(conn, ~p"/books/#{book}/balance")

    assert html =
             live
             |> element("#reopen-book", "Reopen")
             |> render_click()

    assert html =~ "Book reopened successfully"
    refute book |> Repo.reload() |> Books.closed?()
  end

  describe "reimbursement modal" do
    # Open the modal
    setup %{conn: conn, book: book} = context do
      {:ok, lv, _html} = live(conn, ~p"/books/#{book}/balance")

      html =
        lv
        |> element("button", "Settle up")
        |> render_click()

      Map.merge(context, %{
        lv: lv,
        html: html
      })
    end

    test "opens the modal with transaction information", %{
      html: html,
      peer_member1: member1,
      peer_member2: member2
    } do
      modal_document =
        html
        |> Floki.parse_document!()
        |> Floki.find("#reimbursement-modal")

      assert input_value(modal_document, "#reimbursement_label") =~ "Reimbursement from "

      assert select_value(modal_document, "#reimbursement_creditor_id") ==
               to_string(member1.id)

      assert select_value(modal_document, "#reimbursement_debtor_id") ==
               to_string(member2.id)

      assert input_value(modal_document, "#reimbursement_amount") == "5.00"
    end

    test "saves new money transfer", %{
      conn: conn,
      lv: lv,
      book: book,
      peer_member1: member1,
      peer_member2: member2
    } do
      assert lv
             |> form("#reimbursement-form",
               reimbursement: %{
                 label: "",
                 creditor_id: member1.id,
                 amount: "-5.0",
                 debtor_id: member2.id,
                 date: ~D[2020-01-01]
               }
             )
             |> render_submit() =~ "can&#39;t be blank"

      {:ok, _, html} =
        lv
        |> form("#reimbursement-form",
          reimbursement: %{
            label: "My label",
            creditor_id: member2.id,
            amount: "3.0",
            debtor_id: member1.id,
            date: ~D[2020-01-01]
          }
        )
        |> render_submit()
        |> follow_redirect(conn, ~p"/books/#{book}/transfers")

      assert html =~ "Reimbursement created successfully"
    end
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

  defp input_value(document, selector) do
    document
    |> Floki.attribute(selector, "value")
    |> hd()
  end

  defp select_value(document, selector) do
    document
    |> Floki.find(selector)
    |> Floki.attribute("[selected]", "value")
    |> hd()
  end
end
