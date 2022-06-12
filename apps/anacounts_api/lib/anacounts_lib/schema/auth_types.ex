defmodule AnacountsAPI.Schema.AuthTypes do
  @moduledoc """
  Objects related to the `Anacounts.Auth` module.
  """

  use Absinthe.Schema.Notation

  alias AnacountsAPI.Resolvers

  ## Entities

  @desc "The profile of authenticated user"
  object :profile do
    # identification
    field(:id, :id)

    # authentication
    field(:email, :string)
    field(:confirmed_at, :naive_datetime)

    # display information
    field(:display_name, :string)

    field(:avatar_url, :string) do
      resolve(&Resolvers.Auth.get_profile_avatar_url/3)
    end
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

    @desc "Invalidates the token"
    field :invalidate_token, :string do
      arg(:token, non_null(:string))

      resolve(&Resolvers.Auth.do_invalidate_token/3)
    end

    @desc "Invalidates all tokens of the current user"
    field :invalidate_all_tokens, :string do
      resolve(&Resolvers.Auth.do_invalidate_all_tokens/3)
    end

    @desc "Registers a new user"
    field :register, :string do
      arg(:email, non_null(:string))
      arg(:password, non_null(:string))

      resolve(&Resolvers.Auth.do_register/3)
    end

    @desc "Update the user profile"
    field :update_profile, :profile do
      arg(:attrs, non_null(:profile_input))

      resolve(&Resolvers.Auth.do_update_profile/3)
    end
  end

  ## Input objects
  @desc "Used to update profile"
  input_object :profile_input do
    field(:display_name, non_null(:string))
  end
end
