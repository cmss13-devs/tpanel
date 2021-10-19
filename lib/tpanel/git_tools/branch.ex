defmodule Tpanel.GitTools.Branch do
  use Ecto.Schema
  import Ecto.Changeset

  schema "branches" do
    field :description, :string
    field :name, :string
    field :refspec, :string
    field :remote, :string
    field :revision, :string
    belongs_to :mix, Tpanel.GitTools.TextMix

    timestamps()
  end

  @doc false
  def changeset(branch, attrs) do
    branch
    |> cast(attrs, [:name, :description, :remote, :refspec, :revision])
    |> validate_required([:name, :remote, :refspec])
    |> unique_constraint(:name)
  end
end
