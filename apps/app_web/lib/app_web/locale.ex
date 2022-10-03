defmodule AppWeb.Locale do
  @moduledoc """
  This module provides locale fetching and setting functionalities.

  It can be used as a plug in a pipeline to set the locale in the session,
  and as an `on_mount` hook for live views to set the locale.
  """

  import Plug.Conn

  def init(default), do: default

  # Fetch the locale from the request headers, and set it in the conn session.
  def call(conn, _default) do
    # The Accept-Language header is a comma-separated list of language tags.
    # The first tag is the most preferred language.
    # e.g. Accept-Language: en-US,en;q=0.9,el;q=0.8
    # See https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Accept-Language

    case get_req_header(conn, "accept-language") do
      [accept_language_header | _] ->
        locale = parse_locale(accept_language_header)

        Gettext.put_locale(AppWeb.Gettext, locale)
        put_session(conn, :locale, locale)

      [] ->
        conn
    end
  end

  defp parse_locale(accept_languages) do
    # "en;q=0.9,el;q=0.8"
    # => "en;q=0.9"
    favorite_language =
      accept_languages
      |> String.split(",")
      |> List.first()

    # => "en"
    favorite_language
    |> String.split(";")
    |> List.first()
  end

  # Fetch the locale from the session, and set it for the current process.
  # If the locale is not set in the session, use the default.
  def on_mount(:default, _params, %{"locale" => locale} = _session, socket) do
    Gettext.put_locale(AppWeb.Gettext, locale)
    {:cont, socket}
  end

  # for any logged out routes
  def on_mount(:default, _params, _session, socket), do: {:cont, socket}
end
