defmodule AppWeb.UserSettingsBalanceController do
  use AppWeb, :controller

  alias App.Accounts.Balance

  plug :assign_changesets

  def edit(conn, _params) do
    render(conn, "edit.html", page_title: gettext("Balance Settings"))
  end

  def update(conn, %{"user_params" => user_params}) do
    # TODO Maybe user/user_id should be the first param of `upsert_user_params`
    params = Map.put(user_params, "user_id", conn.assigns.current_user.id)

    case Balance.upsert_user_params(params) do
      {:ok, _user_params} ->
        conn
        |> put_flash(:info, gettext("Balance settings updated"))
        |> redirect(to: Routes.user_settings_balance_path(conn, :edit))

      {:error, changeset} ->
        render(conn, "edit.html", %{
          :page_title => gettext("Balance Settings"),
          String.to_existing_atom("#{user_params["means_code"]}_changeset") => changeset
        })
    end
  end

  # TODO Does not belong here
  @default_user_params [%{means_code: :weight_by_income, params: nil, user_id: 0}]

  defp assign_changesets(conn, _opts) do
    # TODO There MUST be a better way to do this
    user_params =
      Balance.find_user_params(conn.assigns.current_user.id)
      |> Enum.map(&Map.from_struct/1)
      |> Kernel.++(@default_user_params)
      |> Enum.uniq_by(& &1.means_code)

    for user_param <- user_params, reduce: conn do
      conn ->
        assign(
          conn,
          String.to_existing_atom("#{user_param.means_code}_changeset"),
          Balance.UserParams.changeset(user_param)
        )
    end
  end
end
