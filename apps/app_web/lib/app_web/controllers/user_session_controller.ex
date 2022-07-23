defmodule AppWeb.UserSessionController do
  use AppWeb, :controller

  alias App.Auth
  alias AppWeb.UserAuth

  def new(conn, _params) do
    render(conn, "new.html", page_title: gettext("Log in"), error_message: nil)
  end

  def create(conn, %{"user" => user_params}) do
    %{"email" => email, "password" => password} = user_params

    if user = Auth.get_user_by_email_and_password(email, password) do
      UserAuth.log_in_user(conn, user, user_params)
    else
      # In order to prevent user enumeration attacks, don't disclose whether the email is registered.
      render(conn, "new.html",
        page_title: gettext("Log in"),
        error_message: gettext("Invalid email or password")
      )
    end
  end

  def delete(conn, _params) do
    conn
    |> put_flash(:info, gettext("Logged out successfully."))
    |> UserAuth.log_out_user()
  end
end
