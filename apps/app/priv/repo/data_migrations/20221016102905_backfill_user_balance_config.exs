defmodule App.Repo.Migrations.BackfillUserBalanceConfig do
  use Ecto.Migration
  import Ecto.Query

  alias App.Auth
  alias App.Balance

  require Logger

  @disable_ddl_transaction true
  @disable_migration_lock true
  @batch_size 50
  @throttle_ms 500

  def up do
    # The Vault must be started as some data will be encrypted
    {:ok, _pid} = App.Vault.start_link()

    throttle_change_in_batches(&page_query/0, &do_change/1)
  end

  def down, do: :ok

  def do_change(rows) do
    for row <- rows do
      {:ok, user_config} =
        Auth.get_user!(row.user_id)
        |> Balance.get_user_config_or_default()
        |> Balance.update_user_config(%{annual_income: row.income})

      user_config.id
    end
  end

  def page_query() do
    # Do not use Ecto schemas here.
    from p in "balance_user_params",
      select: %{id: p.id, user_id: p.user_id, income: p.params["income"]},
      where: p.means_code == "weight_by_income",
      where: p.user_id not in subquery(from c in "user_balance_config", select: c.user_id),
      order_by: [asc: p.id],
      limit: @batch_size
  end

  defp throttle_change_in_batches(query_fun, change_fun) do
    case repo().all(query_fun.(), log: :info, timeout: :infinity) do
      [] ->
        :ok

      rows ->
        results = change_fun.(List.flatten(rows))
        Logger.info("Processed #{length(results)} items: #{inspect(results)}")
        Process.sleep(@throttle_ms)
        throttle_change_in_batches(query_fun, change_fun)
    end
  end
end
