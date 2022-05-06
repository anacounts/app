defmodule AnacountsAPI.Resolvers.Auth do
  @moduledoc """
  Resolve queries and mutations from
  the `AnacountsAPI.Schema.AuthTypes` module.
  """
  use AnacountsAPI, :resolver

  alias Anacounts.Auth

  ## Auth queries

  def find_profile(_parent, _args, %{context: %{current_user: user}}) do
    {:ok, user}
  end

  ## Auth mutations

  def find_profile(_parent, _args, _resolution), do: not_logged_in()

  def do_log_in(_parent, %{email: email, password: password}, _resolution) do
    if user = Auth.get_user_by_email_and_password(email, password) do
      token = Auth.generate_user_session_token(user)

      {:ok, token}
    else
      {:error, "incorrect email or password"}
    end
  end

  def do_register(_parent, args, _resolution) do
    case Auth.register_user(args) do
      {:ok, user} ->
        {:ok, _} =
          Auth.deliver_user_confirmation_instructions(
            user,
            &"/accounts/register/confirm?confirmation_token=#{&1}"
          )

        {:ok, "confirmation instructions sent"}

      {:error, _changeset} = result ->
        result
    end
  end

  ## Field resolution
  def find_book_users(book, _args, %{context: %{current_user: _user}}) do
    Anacounts.Accounts.find_book_users(book)
    |> Enum.map(&book_user_schema_to_book_user_type/1)
    |> wrap()
  end

  def find_book_users(_parent, _args, _resolution), do: not_logged_in()

  defp book_user_schema_to_book_user_type(%{user: %{id: id, email: email}, role: role}) do
    %{
      id: id,
      email: email,
      role: role
    }
  end
end
