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
end
