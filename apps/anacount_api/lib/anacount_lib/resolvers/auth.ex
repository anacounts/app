defmodule AnacountAPI.Resolvers.Auth do
  @moduledoc """
  Resolve queries and mutations from
  the `AnacountAPI.Schema.AuthTypes` module.
  """

  alias Anacount.Auth

  def find_profile(_parent, _args, %{context: %{current_user: user}}) do
    {:ok, user}
  end

  def find_profile(_parent, _args, _resolution) do
    {:error, "You must be logged in"}
  end

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
end
