defmodule Tpanel.GitToolsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Tpanel.GitTools` context.
  """

  @doc """
  Generate a branch.
  """
  def branch_fixture(attrs \\ %{}) do
    {:ok, branch} =
      attrs
      |> Enum.into(%{
        description: "some description",
        name: "some name",
        refspec: "some refspec",
        remote: "some remote"
      })
      |> Tpanel.GitTools.create_branch()

    branch
  end
end
