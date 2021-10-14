defmodule Tpanel.Repo.Migrations.CreateBranches do
  use Ecto.Migration

  def change do
    create table(:branches) do
      add :name, :string
      add :description, :string
      add :remote, :string
      add :refspec, :string

      timestamps()
    end

    create unique_index(:branches, [:name])
  end
end
