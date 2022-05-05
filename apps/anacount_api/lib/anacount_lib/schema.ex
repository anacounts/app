defmodule AnacountAPI.Schema do
  @moduledoc """
  Schema of the GraphQL API. Entrypoint of Absinthe types.
  """

  use Absinthe.Schema

  import_types(Absinthe.Type.Custom)
  import_types(AnacountAPI.Schema.AccountTypes)

  query do
    import_fields(:account_queries)
  end

  mutation do
    import_fields(:account_mutations)
  end

  # if it's a field for the mutation object, add this middleware to the end
  def middleware(middleware, _field, %{identifier: :mutation}) do
    middleware ++ [AnacountAPI.Middlewares.HandleChangesetErrors]
  end

  # if it's any other object keep things as is
  def middleware(middleware, _field, _object), do: middleware
end
