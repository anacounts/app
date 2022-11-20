defmodule AppWeb.UserRegistrationController do
  use AppWeb, :controller

  alias App.Auth
  alias App.Auth.User
  alias AppWeb.UserAuth

  plug :put_layout, "auth.html"

  def new(conn, _params) do
    changeset = Auth.change_user_registration(%User{})
    render(conn, "new.html", page_title: gettext("Create an account"), changeset: changeset)
  end

  def create(conn, %{"user" => user_params}) do
    case Auth.register_user(user_params) do
      {:ok, user} ->
        {:ok, _} =
          Auth.deliver_user_confirmation_instructions(
            user,
            &Routes.user_confirmation_url(conn, :edit, &1)
          )

        conn
        |> put_flash(:info, gettext("User created successfully."))
        |> UserAuth.log_in_user(user)

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "new.html", page_title: gettext("Create an account"), changeset: changeset)
    end
  end
end
