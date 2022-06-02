defmodule Anacounts.ReleaseTasks do
  @moduledoc """
  Tasks to be done before launching a new release.
  """

  require Logger

  def migrate do
    Logger.info("***** RUNNING MIGRATIONS *****")
    {:ok, _} = Application.ensure_all_started(:anacounts)

    path = Application.app_dir(:anacounts, "priv/repo/migrations")

    Ecto.Migrator.run(Anacounts.Repo, path, :up, all: true)
    Logger.info("***** FINISHED MIGRATIONS *****")
  end
end
