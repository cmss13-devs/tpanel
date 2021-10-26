defmodule Tpanel.GitTools.Branch do
  use Ecto.Schema
  import Ecto.Changeset

  schema "branches" do
    field :name, :string
    field :refspec, :string
    field :remote, :string
    field :target_revision, :string
    field :fetched_revision, :string
    field :built_revision, :string
    field :priority, :integer, default: 1
    belongs_to :test_mix, Tpanel.GitTools.TestMix
  end

  @doc false
  def changeset(branch, attrs) do
    branch
    |> cast(attrs, [:name, :remote, :refspec, :target_revision, :fetched_revision, :built_revision, :priority])
    |> validate_required([:name, :remote, :refspec])
    |> validate_format(:name, ~r/^[0-9a-zA-Z\-_]+/)
    |> validate_format(:remote, ~r/^[0-9a-zA-Z\-_\/:%@]+/)
    |> validate_format(:refspec, ~r/^[0-9a-zA-Z\-_\/]+/)
    |> validate_format(:target_revision, ~r/^[[:alnum:]]{40}$/)
    |> validate_format(:fetched_revision, ~r/^[[:alnum:]]{40}$/)
    |> validate_format(:built_revision, ~r/^[[:alnum:]]{40}$/)
    |> assoc_constraint(:test_mix)
    |> unique_constraint(:mix_branch_unicity, name: :test_mix_unique_branch_name)
  end
end
