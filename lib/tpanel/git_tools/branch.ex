defmodule Tpanel.GitTools.Branch do
  use Ecto.Schema
  import Ecto.Changeset

  schema "branches" do
    field :name, :string
    field :refspec, :string
    field :remote, :string
    field :revision, :string
    belongs_to :test_mix, Tpanel.GitTools.TestMix
  end

  @doc false
  def changeset(branch, attrs) do
    branch
    |> cast(attrs, [:name, :remote, :refspec, :revision])
    |> validate_required([:name, :remote, :refspec])
    |> assoc_constraint(:test_mix)
    |> unique_constraint(:mix_branch_unicity, name: :test_mix_unique_branch_name)
  end
end
