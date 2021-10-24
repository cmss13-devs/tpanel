defmodule Tpanel.GitTools.TestMix do
  use Ecto.Schema
  import Ecto.Changeset

  schema "testmixes" do
    field :name, :string
    field :last_build, :date
    field :last_fetch, :date
    field :base_branch_id, :id
    has_many :branches, Tpanel.GitTools.Branch
    timestamps()
  end

  @doc false
  def changeset(test_mix, attrs) do
    test_mix
    |> cast(attrs, [:name, :last_fetch, :last_build, :base_branch_id])
    |> validate_required([:name])
    |> validate_format(:name, ~r/^[0-9a-zA-Z\-_]+/)
    |> foreign_key_constraint(:base_branch_id)
    |> unique_constraint(:name)
  end
end
