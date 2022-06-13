defmodule AnacountsAPI.Schema do
  @moduledoc """
  Schema of the GraphQL API. Entrypoint of Absinthe types.
  """

  use Absinthe.Schema

  import_types(Absinthe.Type.Custom)
  import_types(AnacountsAPI.Schema.AccountsTypes)
  import_types(AnacountsAPI.Schema.AuthTypes)

  query do
    import_fields(:accounts_queries)
    import_fields(:auth_queries)
  end

  mutation do
    import_fields(:accounts_mutations)
    import_fields(:auth_mutations)
  end

  # if it's a field for the mutation object, add this middleware to the end
  def middleware(middleware, _field, %{identifier: :mutation}) do
    middleware ++
      [
        AnacountsAPI.Middlewares.HandleChangesetErrors,
        AnacountsAPI.Middlewares.NormalizeErrors
      ]
  end

  def middleware(middleware, _field, %{identifier: :query}) do
    # credo:disable-for-next-line Credo.Check.Refactor.AppendSingleItem
    middleware ++ [AnacountsAPI.Middlewares.NormalizeErrors]
  end

  # if it's any other object keep things as is
  def middleware(middleware, _field, _object), do: middleware
end
