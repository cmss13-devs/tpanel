defmodule Tpanel.Repo.Migrations.Base do
  use Ecto.Migration

  def change do

    create table(:testmixes) do
      add :name, :string
      add :lastbuild, :date
      add :basebranch, :string
      timestamps()
    end

    create table(:branches) do
      add :name, :string
      add :description, :string
      add :remote, :string
      add :refspec, :string
      add :revision, :string
      add :mix, references(:testmixes)
      timestamps()
    end
    
    create unique_index(:branches, [:name])
    create unique_index(:testmixes, [:name])
  end
end
