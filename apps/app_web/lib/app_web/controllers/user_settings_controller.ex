defmodule AppWeb.UserSettingsController do
  use AppWeb, :controller

  alias App.Auth
  alias AppWeb.UserAuth

  plug :assign_changesets

  def edit(conn, _params) do
    render(conn, "edit.html", page_title: gettext("Settings"))
  end

  def update(conn, %{"action" => "update_display_name"} = params) do
    %{"user" => user_params} = params
    user = conn.assigns.current_user

    case Auth.update_user_display_name(user, user_params) do
      {:ok, _user} ->
        conn
        |> put_flash(:info, gettext("Name updated successfully."))
        |> redirect(to: Routes.user_settings_path(conn, :edit))

      {:error, changeset} ->
        render(conn, "edit.html",
          page_title: gettext("Settings"),
          display_name_changeset: changeset
        )
    end
  end

  def update(conn, %{"action" => "update_email"} = params) do
    %{"current_password" => password, "user" => user_params} = params
    user = conn.assigns.current_user

    case Auth.apply_user_email(user, password, user_params) do
      {:ok, applied_user} ->
        Auth.deliver_update_email_instructions(
          applied_user,
          user.email,
          &Routes.user_settings_url(conn, :confirm_email, &1)
        )

        conn
        |> put_flash(
          :info,
          gettext("A link to confirm your email change has been sent to the new address.")
        )
        |> redirect(to: Routes.user_settings_path(conn, :edit))

      {:error, changeset} ->
        render(conn, "edit.html", page_title: gettext("Settings"), email_changeset: changeset)
    end
  end

  def update(conn, %{"action" => "update_password"} = params) do
    %{"current_password" => password, "user" => user_params} = params
    user = conn.assigns.current_user

    case Auth.update_user_password(user, password, user_params) do
      {:ok, user} ->
        conn
        |> put_flash(:info, "Password updated successfully.")
        |> put_session(:user_return_to, Routes.user_settings_path(conn, :edit))
        |> UserAuth.log_in_user(user)

      {:error, changeset} ->
        render(conn, "edit.html", page_title: gettext("Settings"), password_changeset: changeset)
    end
  end

  def confirm_email(conn, %{"token" => token}) do
    case Auth.update_user_email(conn.assigns.current_user, token) do
      :ok ->
        conn
        |> put_flash(:info, gettext("Email changed successfully."))
        |> redirect(to: Routes.user_settings_path(conn, :edit))

      :error ->
        conn
        |> put_flash(:error, gettext("Email change link is invalid or it has expired."))
        |> redirect(to: Routes.user_settings_path(conn, :edit))
    end
  end

  defp assign_changesets(conn, _opts) do
    user = conn.assigns.current_user

    conn
    |> assign(:display_name_changeset, Auth.change_user_display_name(user))
    |> assign(:email_changeset, Auth.change_user_email(user))
    |> assign(:password_changeset, Auth.change_user_password(user))
  end
end
