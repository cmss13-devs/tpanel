defmodule Tpanel.GitTools.TestMix do
  use Ecto.Schema
  import Ecto.Changeset

  schema "testmixes" do
    field :name, :string
    field :last_build, :utc_datetime
    field :last_fetch, :utc_datetime
    has_many :branches, Tpanel.GitTools.Branch
    timestamps()
  end

  @doc false
  def changeset(test_mix, attrs) do
    test_mix
    |> cast(attrs, [:name, :last_fetch, :last_build])
    |> validate_required([:name])
    |> validate_format(:name, ~r/^[0-9a-zA-Z\-_]+$/)
    |> unique_constraint(:name)
  end
end
