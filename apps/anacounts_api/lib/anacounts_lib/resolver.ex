defmodule AnacountsAPI.Resolver do
  @moduledoc """
  A module imported in every resolvers.
  """

  import AnacountsAPI.Gettext

  @doc """
  Wraps an Ecto `get` result into a Absinthe compatible value.
  """
  def wrap(nil), do: {:error, :not_found}
  def wrap(value), do: {:ok, value}

  @doc """
  An error to return when the user must be logged in to get the query result.
  """
  def not_logged_in, do: {:error, dgettext("api_errors", "You must be logged in")}
end
