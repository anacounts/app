defmodule AnacountsAPI.Schema.Accounts.BalanceTypes do
  @moduledoc """
  Objects related to the `Anacounts.Account` module.
  """

  use Absinthe.Schema.Notation

  alias AnacountsAPI.Resolvers.Accounts.Balance

  ## Entities

  # TODO needs @desc
  # TODO remove those inline `resolve`
  # TODO Use `dataloader` https://hexdocs.pm/absinthe/batching.html#dataloader

  object :book_balance do
    field(:members_balance, list_of(:member_balance))
    field(:transactions, list_of(:transaction))
  end

  object :member_balance do
    field(:member, :book_member) do
      resolve(fn %{member_id: member_id}, _, _ ->
        {:ok, Anacounts.Accounts.get_member!(member_id)}
      end)
    end

    field(:amount, :money)
  end

  object :transaction do
    field(:from, :book_member) do
      resolve(fn %{from: from}, _, _ ->
        {:ok, Anacounts.Accounts.get_member!(from)}
      end)
    end

    field(:to, :book_member) do
      resolve(fn %{to: to}, _, _ ->
        {:ok, Anacounts.Accounts.get_member!(to)}
      end)
    end

    field(:amount, :money)
  end

  @desc """
  The differents means to balance a money transfer.
  Each has their own particularities and may require parameters either
  on the transfer (e.g. a coefficient), or on the user (e.g. their revenue).
  """
  enum :balance_means_code do
    value(:divide_equally)
  end

  @desc """
  Indicates how a transfer must be balanced.
  """
  object :balance_transfer_params do
    field(:means_code, :balance_means_code)
    field(:params, :json)
  end

  @desc """
  Gives information about the user required for a certain means to balance money transfers.
  """
  object :balance_user_params do
    field(:means_code, :balance_means_code)
    field(:params, :json)
  end

  ## Queries

  object :balance_queries do
    @desc "Get all balance params for current user"
    field :balance_user_params, list_of(:balance_user_params) do
      resolve(&Balance.find_balance_user_params/3)
    end
  end

  ## Mutations

  object :balance_mutations do
    field :set_balance_user_params, :balance_user_params do
      arg(:means_code, non_null(:balance_means_code))
      arg(:params, non_null(:json))

      resolve(&Balance.do_set_balance_user_params/3)
    end

    field :delete_balance_user_params, :balance_user_params do
      arg(:means_code, non_null(:balance_means_code))

      resolve(&Balance.do_delete_balance_user_params/3)
    end
  end

  ## Input object

  input_object :balance_transfer_params_input do
    field(:means_code, non_null(:balance_means_code))
    field(:params, non_null(:json))
  end

  input_object :balance_user_params_input do
    field(:means_code, non_null(:balance_means_code))
    field(:params, non_null(:json))
  end
end
