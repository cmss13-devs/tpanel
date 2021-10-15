defmodule Tpanel.Repo.Migrations.BranchesAddRevisionColumn do
  use Ecto.Migration

  def change do
    alter table("branches") do
      add :revision, :string
    end
  end
end
