defmodule AppWeb.PageController do
  use AppWeb, :controller

  def index(conn, _params) do
    if conn.assigns[:current_user] do
      redirect(conn, to: Routes.book_index_path(conn, :index))
    else
      redirect(conn, to: Routes.user_session_path(conn, :new))
    end
  end
end
