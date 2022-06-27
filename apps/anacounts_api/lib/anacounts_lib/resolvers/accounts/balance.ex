defmodule AnacountsAPI.Resolvers.Accounts.Balance do
  @moduledoc """
  Resolve queries and mutations from
  the `AnacountsAPI.Schema.Accounts.BalanceTypes` module.
  """
  use AnacountsAPI, :resolver

  alias Anacounts.Accounts.Balance

  def get_book_balance(book, _args, _resolution) do
    raw_book_balance = Balance.for_book(book.id)

    # TODO I'd rather be able to remove this
    book_balance =
      Map.update!(raw_book_balance, :members_balance, fn members_balance ->
        Enum.map(members_balance, fn {member_id, weight} ->
          %{member_id: member_id, amount: weight}
        end)
      end)

    {:ok, book_balance}
  end
end
