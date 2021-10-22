defmodule Tpanel.GitTools.TestMix do
  use Ecto.Schema
  import Ecto.Changeset

  schema "testmixes" do
    field :name, :string
    field :lastbuild, :date
    field :base_branch_id, :id
    has_many :branches, Tpanel.GitTools.Branch
    timestamps()
  end

  @doc false
  def changeset(test_mix, attrs) do
    test_mix
    |> cast(attrs, [:name, :lastbuild, :base_branch_id])
    |> validate_required([:name])
    |> foreign_key_constraint(:base_branch_id)
    |> unique_constraint(:name)
  end
end
