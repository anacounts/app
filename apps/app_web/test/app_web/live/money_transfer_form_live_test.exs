defmodule AppWeb.MoneyTransferFormLiveTest do
  use AppWeb.ConnCase

  import Phoenix.LiveViewTest
  import App.BooksFixtures
  import App.Books.MembersFixtures
  import App.TransfersFixtures

  alias App.Repo
  alias App.Transfers.Peer

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
    type: "income",
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

  setup [
    :register_and_log_in_user,
    :book_with_member_context,
    :money_transfer_in_book_context
  ]

  test "displays money transfer", %{conn: conn, book: book, money_transfer: money_transfer} do
    {:ok, _form_live, html} = live(conn, ~p"/books/#{book}/transfers/#{money_transfer}/edit")

    assert html =~ "Transfer"
    assert html =~ "<form"
  end

  test "saves new money_transfer", %{conn: conn, book: book} do
    {:ok, form_live, _html} = live(conn, ~p"/books/#{book}/transfers/new")

    assert form_live
           |> form("#money-transfer-form", money_transfer: @invalid_attrs)
           |> render_change() =~ "is invalid"

    {:ok, _, html} =
      form_live
      |> form("#money-transfer-form", money_transfer: @create_attrs)
      |> render_submit()
      |> follow_redirect(conn, ~p"/books/#{book}/transfers")

    assert html =~ "Money transfer created successfully"
  end

  test "updates money transfer", %{conn: conn, book: book, money_transfer: money_transfer} do
    {:ok, form_live, _html} = live(conn, ~p"/books/#{book}/transfers/#{money_transfer}/edit")

    assert form_live
           |> form("#money-transfer-form", money_transfer: @invalid_attrs)
           |> render_change() =~ "is invalid"

    {:ok, _, html} =
      form_live
      |> form("#money-transfer-form", money_transfer: @update_attrs)
      |> render_submit()
      |> follow_redirect(conn, ~p"/books/#{book}/transfers")

    assert html =~ "Money transfer updated successfully"
  end

  test "update the peers instead of deleting them", %{conn: conn, book: book} do
    member = book_member_fixture(book)

    money_transfer =
      money_transfer_fixture(book, tenant_id: member.id, peers: [%{member_id: member.id}])

    {:ok, form_live, _html} = live(conn, ~p"/books/#{book}/transfers/#{money_transfer}/edit")

    {:ok, _, html} =
      form_live
      |> form("#money-transfer-form", money_transfer: @update_attrs)
      |> render_submit()
      |> follow_redirect(conn, ~p"/books/#{book}/transfers")

    assert html =~ "Money transfer updated successfully"

    original_peer_ids = Enum.map(money_transfer.peers, & &1.id)

    new_peer_ids =
      Peer
      |> Repo.all(transfer_id: money_transfer.id)
      |> Enum.map(& &1.id)

    assert original_peer_ids == new_peer_ids
  end

  test "deletes money transfer", %{conn: conn, book: book, money_transfer: money_transfer} do
    {:ok, form_live, _html} = live(conn, ~p"/books/#{book}/transfers/#{money_transfer}/edit")

    {:ok, _, html} =
      form_live
      |> element("#delete-money-transfer", "Delete")
      |> render_click()
      |> follow_redirect(conn, ~p"/books/#{book}/transfers")

    assert html =~ "Transfer deleted successfully"
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

  # Depends on :book_with_member_context
  defp money_transfer_in_book_context(%{book: book, member: member} = context) do
    Map.put(
      context,
      :money_transfer,
      money_transfer_fixture(book, tenant_id: member.id)
    )
  end
end
