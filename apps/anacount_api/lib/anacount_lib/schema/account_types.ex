defmodule AnacountAPI.Schema.AccountTypes do
  @moduledoc """
  Objects related to the `Anacount.Accounts` module.
  """

  use Absinthe.Schema.Notation

  alias AnacountAPI.Resolvers

  @desc "A user of the app"
  object :user do
    field(:id, :id)
    field(:email, :string)
    field(:confirmed_at, :naive_datetime)
  end

  object :account_queries do
    @desc "Get the current user information"
    field :profile, :user do
      resolve(&Resolvers.Accounts.find_profile/3)
    end
  end

  object :account_mutations do
    @desc "Validates the authentication information of a user, and sends back an auth token"
    field :log_in, :string do
      arg(:email, non_null(:string))
      arg(:password, non_null(:string))

      resolve(&Resolvers.Accounts.do_log_in/3)
    end

    @desc "Registers a new user"
    field :register, :string do
      arg(:email, non_null(:string))
      arg(:password, non_null(:string))

      resolve(&Resolvers.Accounts.do_register/3)
    end
  end
end
