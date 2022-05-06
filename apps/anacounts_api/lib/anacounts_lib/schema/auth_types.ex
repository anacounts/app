defmodule AnacountsAPI.Schema.AuthTypes do
  @moduledoc """
  Objects related to the `Anacounts.Auth` module.
  """

  use Absinthe.Schema.Notation

  alias AnacountsAPI.Resolvers

  ## Entities

  @desc "A user of the app. May be extended to provide more information based on the context"
  interface :base_user do
    field(:id, :id)
    field(:email, :string)
  end

  @desc "The profile of authenticated user"
  object :profile do
    interface(:base_user)
    is_type_of(&match?(%{confirmed_at: _}, &1))

    field(:id, :id)
    field(:email, :string)
    field(:confirmed_at, :naive_datetime)
  end

  ## Queries

  object :auth_queries do
    @desc "Get the current user information"
    field :profile, :profile do
      resolve(&Resolvers.Auth.find_profile/3)
    end
  end

  ## Mutations

  object :auth_mutations do
    @desc "Validates the authentication information of a user, and sends back an auth token"
    field :log_in, :string do
      arg(:email, non_null(:string))
      arg(:password, non_null(:string))

      resolve(&Resolvers.Auth.do_log_in/3)
    end

    @desc "Registers a new user"
    field :register, :string do
      arg(:email, non_null(:string))
      arg(:password, non_null(:string))

      resolve(&Resolvers.Auth.do_register/3)
    end
  end
end
