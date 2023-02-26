defmodule AppWeb.UserSettingsBalanceController do
  use AppWeb, :controller

  alias App.Balance.BalanceConfigs

  plug :assign_user_config

  def edit(conn, _params) do
    render(conn, "edit.html", page_title: gettext("Balance Settings"))
  end

  def update(conn, %{"user_config" => user_config_params}) do
    case BalanceConfigs.update_user_config(conn.assigns.user_config, user_config_params) do
      {:ok, _user_config} ->
        conn
        |> put_flash(:info, gettext("Balance settings updated"))
        |> redirect(to: Routes.user_settings_balance_path(conn, :edit))

      {:error, changeset} ->
        render(conn, "edit.html",
          page_title: gettext("Balance Settings"),
          changeset: changeset
        )
    end
  end

  defp assign_user_config(conn, _opts) do
    user_config = BalanceConfigs.get_user_config_or_default(conn.assigns.current_user)

    conn
    |> assign(:user_config, user_config)
    |> assign(:changeset, BalanceConfigs.change_user_config(user_config))
  end
end
