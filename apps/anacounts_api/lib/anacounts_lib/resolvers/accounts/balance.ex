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

  ## Queries

  def find_balance_user_params(_parent, _args, %{context: %{current_user: user}}) do
    {:ok, Balance.find_user_params(user.id)}
  end

  def find_balance_user_params(_parent, _args, _resolution), do: not_logged_in()

  ## Mutations

  @spec do_set_balance_user_params(any, any, any) ::
          {:error, binary | Ecto.Changeset.t()} | {:ok, Anacounts.Accounts.Balance.UserParams.t()}
  def do_set_balance_user_params(
        _parent,
        %{means_code: _means_code, params: _params} = attrs,
        %{context: %{current_user: user}}
      ) do
    attrs_with_user = Map.put(attrs, :user_id, user.id)

    Balance.upsert_user_params(attrs_with_user)
  end

  def do_set_balance_user_params(_parent, _args_, _resolution), do: not_logged_in()

  def do_delete_balance_user_params(
        _parent,
        %{means_code: means_code},
        %{context: %{current_user: user}}
      ) do
    case fetch_user_params(means_code, user.id) do
      {:ok, user_param} ->
        Balance.delete_user_params(user_param)

      {:error, _} = error ->
        error
    end
  end

  def do_delete_balance_user_params(_parent, _args_, _resolution), do: not_logged_in()

  defp fetch_user_params(means_code, user_id) do
    if user_param = Balance.get_user_params_with_code(user_id, means_code) do
      {:ok, user_param}
    else
      {:error, :not_found}
    end
  end
end
