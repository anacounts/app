defmodule AnacountsAPI.Schema.Accounts.BalanceTypes do
  @moduledoc """
  Objects related to the `Anacounts.Account` module.
  """

  use Absinthe.Schema.Notation

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

  ## Input object
  input_object :balance_transfer_params_input do
    field(:means_code, non_null(:balance_means_code))
    field(:params, non_null(:json))
  end
end
