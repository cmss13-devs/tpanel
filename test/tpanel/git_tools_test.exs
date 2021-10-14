defmodule Tpanel.GitToolsTest do
  use Tpanel.DataCase

  alias Tpanel.GitTools

  describe "branches" do
    alias Tpanel.GitTools.Branch

    import Tpanel.GitToolsFixtures

    @invalid_attrs %{description: nil, name: nil, refspec: nil, remote: nil}

    test "list_branches/0 returns all branches" do
      branch = branch_fixture()
      assert GitTools.list_branches() == [branch]
    end

    test "get_branch!/1 returns the branch with given id" do
      branch = branch_fixture()
      assert GitTools.get_branch!(branch.id) == branch
    end

    test "create_branch/1 with valid data creates a branch" do
      valid_attrs = %{description: "some description", name: "some name", refspec: "some refspec", remote: "some remote"}

      assert {:ok, %Branch{} = branch} = GitTools.create_branch(valid_attrs)
      assert branch.description == "some description"
      assert branch.name == "some name"
      assert branch.refspec == "some refspec"
      assert branch.remote == "some remote"
    end

    test "create_branch/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = GitTools.create_branch(@invalid_attrs)
    end

    test "update_branch/2 with valid data updates the branch" do
      branch = branch_fixture()
      update_attrs = %{description: "some updated description", name: "some updated name", refspec: "some updated refspec", remote: "some updated remote"}

      assert {:ok, %Branch{} = branch} = GitTools.update_branch(branch, update_attrs)
      assert branch.description == "some updated description"
      assert branch.name == "some updated name"
      assert branch.refspec == "some updated refspec"
      assert branch.remote == "some updated remote"
    end

    test "update_branch/2 with invalid data returns error changeset" do
      branch = branch_fixture()
      assert {:error, %Ecto.Changeset{}} = GitTools.update_branch(branch, @invalid_attrs)
      assert branch == GitTools.get_branch!(branch.id)
    end

    test "delete_branch/1 deletes the branch" do
      branch = branch_fixture()
      assert {:ok, %Branch{}} = GitTools.delete_branch(branch)
      assert_raise Ecto.NoResultsError, fn -> GitTools.get_branch!(branch.id) end
    end

    test "change_branch/1 returns a branch changeset" do
      branch = branch_fixture()
      assert %Ecto.Changeset{} = GitTools.change_branch(branch)
    end
  end
end
