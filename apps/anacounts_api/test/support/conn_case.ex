defmodule AnacountsAPI.ConnCase do
  @moduledoc """
  This module defines the test case to be used by
  tests that require setting up a connection.

  Such tests rely on `Phoenix.ConnTest` and also
  import other functionality to make it easier
  to build common data structures and query the data layer.

  Finally, if the test case interacts with the database,
  we enable the SQL sandbox, so changes done to the database
  are reverted at the end of every test. If you are using
  PostgreSQL, you can even run database tests asynchronously
  by setting `use AnacountsAPI.ConnCase, async: true`, although
  this option is not recommended for other databases.
  """

  use ExUnit.CaseTemplate

  import Plug.Conn, only: [put_req_header: 3]

  using do
    quote do
      # Import conveniences for testing with connections
      import Plug.Conn
      import Phoenix.ConnTest
      import AnacountsAPI.ConnCase

      # The default endpoint for testing
      @endpoint AnacountsAPI.Endpoint
    end
  end

  setup tags do
    Anacounts.DataCase.setup_sandbox(tags)
    {:ok, conn: Phoenix.ConnTest.build_conn()}
  end

  @doc """
  Log a user in a conn entity.
  """
  def log_user_in(conn, user) do
    user_token = Anacounts.Auth.generate_user_session_token(user)
    put_req_header(conn, "authorization", "Bearer #{user_token}")
  end

  @doc """
  Setup `conn` to log the context's user in.
  The context must contain a `:user` key containing a User entity.
  """
  def setup_log_user_in(%{conn: conn, user: user} = context) do
    Map.put(context, :conn, log_user_in(conn, user))
  end
end
