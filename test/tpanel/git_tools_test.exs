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

  describe "testmixes" do
    alias Tpanel.GitTools.TestMix

    import Tpanel.GitToolsFixtures

    @invalid_attrs %{lastbuild: nil, name: nil}

    test "list_testmixes/0 returns all testmixes" do
      test_mix = test_mix_fixture()
      assert GitTools.list_testmixes() == [test_mix]
    end

    test "get_test_mix!/1 returns the test_mix with given id" do
      test_mix = test_mix_fixture()
      assert GitTools.get_test_mix!(test_mix.id) == test_mix
    end

    test "create_test_mix/1 with valid data creates a test_mix" do
      valid_attrs = %{lastbuild: ~D[2021-10-14], name: "some name"}

      assert {:ok, %TestMix{} = test_mix} = GitTools.create_test_mix(valid_attrs)
      assert test_mix.lastbuild == ~D[2021-10-14]
      assert test_mix.name == "some name"
    end

    test "create_test_mix/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = GitTools.create_test_mix(@invalid_attrs)
    end

    test "update_test_mix/2 with valid data updates the test_mix" do
      test_mix = test_mix_fixture()
      update_attrs = %{lastbuild: ~D[2021-10-15], name: "some updated name"}

      assert {:ok, %TestMix{} = test_mix} = GitTools.update_test_mix(test_mix, update_attrs)
      assert test_mix.lastbuild == ~D[2021-10-15]
      assert test_mix.name == "some updated name"
    end

    test "update_test_mix/2 with invalid data returns error changeset" do
      test_mix = test_mix_fixture()
      assert {:error, %Ecto.Changeset{}} = GitTools.update_test_mix(test_mix, @invalid_attrs)
      assert test_mix == GitTools.get_test_mix!(test_mix.id)
    end

    test "delete_test_mix/1 deletes the test_mix" do
      test_mix = test_mix_fixture()
      assert {:ok, %TestMix{}} = GitTools.delete_test_mix(test_mix)
      assert_raise Ecto.NoResultsError, fn -> GitTools.get_test_mix!(test_mix.id) end
    end

    test "change_test_mix/1 returns a test_mix changeset" do
      test_mix = test_mix_fixture()
      assert %Ecto.Changeset{} = GitTools.change_test_mix(test_mix)
    end
  end
end
