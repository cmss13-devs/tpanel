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

  @doc """
  Generate a unique test_mix name.
  """
  def unique_test_mix_name, do: "some name#{System.unique_integer([:positive])}"

  @doc """
  Generate a test_mix.
  """
  def test_mix_fixture(attrs \\ %{}) do
    {:ok, test_mix} =
      attrs
      |> Enum.into(%{
        lastbuild: ~D[2021-10-14],
        name: unique_test_mix_name()
      })
      |> Tpanel.GitTools.create_test_mix()

    test_mix
  end
end
