defmodule Anacount.Context do
  @behaviour Plug

  import Plug.Conn

  alias Anacount.Accounts

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
    if user = Accounts.get_user_by_session_token(token) do
      {:ok, user}
    else
      {:error, "invalid authorization token"}
    end
  end
end
