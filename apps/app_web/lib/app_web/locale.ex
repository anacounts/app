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
    if locale_tuple = List.keyfind(conn.req_headers, "accept-language", 0) do
      locale = elem(locale_tuple, 1)
      Gettext.put_locale(AppWeb.Gettext, locale)
      put_session(conn, :locale, locale)
    else
      conn
    end
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
