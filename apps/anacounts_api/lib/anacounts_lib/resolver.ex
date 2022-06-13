defmodule AnacountsAPI.Resolver do
  @moduledoc """
  A module imported in every resolvers.
  """

  import AnacountsAPI.Gettext

  @doc """
  An error to return when the user must be logged in to get the query result.
  """
  def not_logged_in, do: {:error, dgettext("api_errors", "You must be logged in")}
end
