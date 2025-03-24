defmodule App.Repo.Migrations.DropOban do
  use Ecto.Migration

  def up do
    Oban.Migration.down()
  end

  def down do
    Oban.Migration.up(version: 12)
  end
end
