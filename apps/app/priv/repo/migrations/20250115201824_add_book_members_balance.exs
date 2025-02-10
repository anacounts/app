defmodule App.Repo.Migrations.AddBookMembersBalance do
  use Ecto.Migration

  def change do
    alter table("book_members") do
      add :balance, :money_with_currency
      add :balance_errors, :map, null: false, default: []
    end
  end
end
