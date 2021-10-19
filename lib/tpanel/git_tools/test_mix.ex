defmodule Tpanel.GitTools.TestMix do
  use Ecto.Schema
  import Ecto.Changeset

  schema "testmixes" do
    field :lastbuild
    field :name, :string
    has_many :branches, Tpanel.GitTools.Branch
    has_one :base_branch, Tpanel.GitTools.Branch
    timestamps()
  end

  @doc false
  def changeset(test_mix, attrs) do
    test_mix
    |> cast(attrs, [:name, :lastbuild])
    |> validate_required([:name])
    |> unique_constraint(:name)
  end
end
