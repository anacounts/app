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

  def find_profile(_parent, _args, _resolution), do: not_logged_in()

  ## Auth mutations

  def do_log_in(_parent, %{email: email, password: password}, _resolution) do
    if user = Auth.get_user_by_email_and_password(email, password) do
      token = Auth.generate_user_session_token(user)

      {:ok, token}
    else
      {:error, "incorrect email or password"}
    end
  end

  def do_invalidate_token(_parent, %{token: token}, %{context: %{current_user: user}}) do
    Auth.delete_token_of_user(token, user)

    wrap("ok")
  end

  def do_invalidate_token(_parent, _args, _resolution), do: not_logged_in()

  def do_invalidate_all_tokens(_parent, _args, %{context: %{current_user: user}}) do
    Auth.delete_all_tokens_of_user(user)

    wrap("ok")
  end

  def do_invalidate_all_tokens(_parent, _args, _resolution), do: not_logged_in()

  def do_register(_parent, args, _resolution) do
    case Auth.register_user(args) do
      {:ok, user} ->
        {:ok, _} =
          Auth.deliver_user_confirmation_instructions(
            user,
            &"/accounts/register/confirm?confirmation_token=#{&1}"
          )

        wrap("ok")

      {:error, _changeset} = result ->
        result
    end
  end

  def do_update_profile(_parent, %{attrs: attrs}, %{context: %{current_user: user}}) do
    Auth.update_user_profile(user, attrs)
  end

  def do_update_profile(_parent, _args, _resolution), do: not_logged_in()

  ## Field resolution

  def get_profile_avatar_url(user, _args, _resolution) do
    gravatar_email_url(user.email)
    |> wrap()
  end

  # Follow Gravatar instructions to generate URLs to request images.
  # If necessary, the clients will be able to add more options by
  # appending `?parameter=value` at the end of the string.
  #
  # ref: https://en.gravatar.com/site/implement/images/
  defp gravatar_email_url(email) do
    hash = gravatar_email_hash(email)
    "https://www.gravatar.com/avatar/#{hash}"
  end

  # Follow Gravatar instructions to hash an email.
  # * Trim leading and trailing whitespace from an email address
  # * Force all characters to lower-case
  # * md5 hash the final string
  #
  # Unlike most tools, erlang does not automatically converts
  # produced binary to base 16, so this is done explicitely afterwards.
  #
  # ref: https://en.gravatar.com/site/implement/hash/
  defp gravatar_email_hash(email) do
    normalized =
      email
      |> String.trim()
      |> String.downcase()

    :crypto.hash(:md5, normalized)
    |> Base.encode16(case: :lower)
  end

  ## External field resolution

  def find_book_members(book, _args, %{context: %{current_user: _user}}) do
    Anacounts.Accounts.find_book_members(book)
    |> Enum.map(&book_member_schema_to_book_member_type/1)
    |> wrap()
  end

  def find_book_members(_parent, _args, _resolution), do: not_logged_in()

  defp book_member_schema_to_book_member_type(%{
         user: %{id: id, email: email, display_name: display_name},
         role: role
       }) do
    %{
      id: id,
      display_name: display_name,
      role: role,

      # email is required to resolve fields of the `book_member` type (e.g. `avatar_url`)
      email: email
    }
  end
end
