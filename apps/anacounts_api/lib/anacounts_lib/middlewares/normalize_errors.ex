defmodule AnacountsAPI.Middlewares.NormalizeErrors do
  @moduledoc """
  A middleware that transforms some atom errors into their respective text translation.

  Enabled by overriding the `middleware` callback in the main schema.
  """
  @behaviour Absinthe.Middleware

  import AnacountsAPI.Gettext

  def call(resolution, _opts) do
    %{resolution | errors: Enum.map(resolution.errors, &handle_error/1)}
  end

  defp handle_error(:not_found), do: dgettext("api_errors", "Not found")
  defp handle_error(:unauthorized), do: dgettext("api_errors", "Unauthorized")
  defp handle_error(error), do: error
end
