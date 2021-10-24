defmodule Tpanel.Repo.Migrations.Base do
  use Ecto.Migration

  def change do

    create table(:testmixes) do
      add :name, :string
      add :last_build, :date
      add :last_fetch, :date
      timestamps()
    end

    create table(:branches) do
      add :name, :string
      add :remote, :string
      add :refspec, :string
      add :target_revision, :string
      add :fetched_revision, :string
      add :built_revision, :string
      add :test_mix_id, references(:testmixes, on_delete: :delete_all), null: false
    end

    alter table(:testmixes) do
      add :base_branch_id, references(:branches, on_delete: :nilify_all)
    end

    create unique_index(:testmixes, [:name])
    create unique_index(:branches, [:test_mix_id, :name], name: :test_mix_unique_branch_name)
  end
end
