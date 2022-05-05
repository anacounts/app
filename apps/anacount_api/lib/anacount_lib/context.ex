defmodule Anacount.Context do
  @moduledoc """
  Provides account context to the Absinthe resolvers.
  Sets a `context.current_user` option in the resolution object
  if a user can be retrieved from the "authorization" token.
  If not, an empty context is set instead.
  """

  @behaviour Plug

  import Plug.Conn

  alias Anacount.Auth

  def init(opts), do: opts

  def call(conn, _opts) do
    context = build_context(conn)
    Absinthe.Plug.put_options(conn, context: context)
  end

  @doc """
  Return the current user context based on the authorization header
  """
  def build_context(conn) do
    with ["Bearer " <> token] <- get_req_header(conn, "authorization"),
         {:ok, current_user} <- authorize(token) do
      %{current_user: current_user}
    else
      _ -> %{}
    end
  end

  defp authorize(token) do
    if user = Auth.get_user_by_session_token(token) do
      {:ok, user}
    else
      {:error, "invalid authorization token"}
    end
  end
end
