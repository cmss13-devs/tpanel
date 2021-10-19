defmodule Tpanel.Repo.Migrations.Base do
  use Ecto.Migration

  def change do

    create table(:branches) do
      add :name, :string
      add :remote, :string
      add :refspec, :string
      add :revision, :string
    end

    create table(:testmixes) do
      add :name, :string
      add :lastbuild, :date
      add :base_branch_id, references(:branches, on_delete: :nilify_all)
      timestamps()
    end

    alter table(:branches) do    
      add :test_mix_id, references(:testmixes, on_delete: :delete_all)
    end

    create unique_index(:testmixes, [:name])
    create unique_index(:branches, [:test_mix_id, :name])
  end
end
