defmodule AnacountsAPI.Schema.AuthTypes do
  @moduledoc """
  Objects related to the `Anacounts.Auth` module.
  """

  use Absinthe.Schema.Notation

  alias AnacountsAPI.Resolvers

  @desc "A user of the app"
  object :user do
    field(:id, :id)
    field(:email, :string)
    field(:confirmed_at, :naive_datetime)
  end

  object :auth_queries do
    @desc "Get the current user information"
    field :profile, :user do
      resolve(&Resolvers.Auth.find_profile/3)
    end
  end

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
