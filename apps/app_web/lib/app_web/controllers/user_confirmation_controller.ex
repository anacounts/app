defmodule AppWeb.UserConfirmationController do
  use AppWeb, :controller

  alias App.Auth

  plug :put_layout, "auth.html"

  def edit(conn, %{"token" => token}) do
    render(conn, "edit.html", page_title: gettext("Confirm your account"), token: token)
  end

  # Do not log in the user after confirmation to avoid a
  # leaked token giving the user access to the account.
  def update(conn, %{"token" => token}) do
    case Auth.confirm_user(token) do
      {:ok, _} ->
        conn
        |> put_flash(:info, gettext("User confirmed successfully."))
        |> redirect(to: "/")

      :error ->
        # If there is a current user and the account was already confirmed,
        # then odds are that the confirmation link was already visited, either
        # by some automation or by the user themselves, so we redirect without
        # a warning message.
        case conn.assigns do
          %{current_user: %{confirmed_at: %{} = _confirmed_at}} ->
            redirect(conn, to: "/")

          %{} ->
            conn
            |> put_flash(:error, gettext("User confirmation link is invalid or it has expired."))
            |> redirect(to: "/")
        end
    end
  end
end
