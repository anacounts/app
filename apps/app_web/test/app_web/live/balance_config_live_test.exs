defmodule AppWeb.BalanceConfigLiveTest do
  use AppWeb.ConnCase

  import Phoenix.LiveViewTest
  import App.AccountsFixtures
  import App.Balance.BalanceConfigsFixtures

  alias App.Repo

  alias App.Balance.BalanceConfigs

  @valid_annual_income 1000
  @updated_annual_income 2000

  describe "Edit page" do
    setup %{conn: conn} do
      user = user_fixture()
      conn = log_in_user(conn, user)

      %{conn: conn, user: user}
    end

    test "renders edit page", %{conn: conn} do
      {:ok, _lv, html} = live(conn, ~p"/users/settings/balance")

      assert html =~ "Balance Settings"
      assert html =~ "Last year incomes"
    end

    test "creates the user balance settings if they don't exist", %{conn: conn, user: user} do
      {:ok, lv, _html} = live(conn, ~p"/users/settings/balance")

      {:ok, conn} =
        lv
        |> form("#balance_config_form", balance_config: %{annual_income: @valid_annual_income})
        |> render_submit()
        |> follow_redirect(conn, ~p"/users/settings")

      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~ "Balance settings updated"

      # assert the balance config was created
      balance_config =
        user
        |> Repo.reload()
        |> BalanceConfigs.get_user_balance_config_or_default()

      assert balance_config.annual_income == @valid_annual_income
    end

    test "updates the user balance settings", %{conn: conn, user: user} do
      user_balance_config_fixture(user, annual_income: @valid_annual_income)

      {:ok, lv, _html} = live(conn, ~p"/users/settings/balance")

      {:ok, conn} =
        lv
        |> form("#balance_config_form", balance_config: %{annual_income: @updated_annual_income})
        |> render_submit()
        |> follow_redirect(conn, ~p"/users/settings")

      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~ "Balance settings updated"

      # assert the balance config was updated
      balance_config =
        user
        |> Repo.reload()
        |> BalanceConfigs.get_user_balance_config_or_default()

      assert balance_config.annual_income == @updated_annual_income
    end
  end
end
