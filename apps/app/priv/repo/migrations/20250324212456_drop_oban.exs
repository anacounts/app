defmodule App.Repo.Migrations.DropOban do
  use Ecto.Migration

  def up do
    Oban.Migration.down(version: 1)
  end

  def down do
    Oban.Migration.up(version: 12)
  end
end
