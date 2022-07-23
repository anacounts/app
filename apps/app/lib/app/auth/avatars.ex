defmodule App.Auth.Avatars do
  @moduledoc """
  Get avatars for users.

  Uses Gravatar as the default avatar provider.
  """

  alias App.Auth.User

  @spec for_user(User.t()) :: String.t()
  def for_user(user) do
    gravatar_email_url(user.email)
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
end
