defmodule App.ReleaseTasks do
  @moduledoc """
  Tasks to be done before launching a new release.
  """

  require Logger

  def migrate do
    Logger.info("***** RUNNING MIGRATIONS *****")
    {:ok, _} = Application.ensure_all_started(:app)

    path = Application.app_dir(:app, "priv/repo/migrations")

    Ecto.Migrator.run(App.Repo, path, :up, all: true)
    Logger.info("***** FINISHED MIGRATIONS *****")
  end
end
