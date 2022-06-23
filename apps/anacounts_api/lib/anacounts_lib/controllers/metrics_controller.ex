defmodule AnacountsAPI.Controllers.MetricsController do
  @moduledoc """
  Get metrics regarding the application.
  """

  use Phoenix.Controller, namespace: AnacountsAPI

  def health_check(conn, _opts) do
    text(conn, "OK")
  end
end
