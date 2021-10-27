defmodule Tpanel.GitTools do
  @moduledoc """
  The GitTools context.
  """

  import Ecto.Query, warn: false
  alias Tpanel.Repo

  alias Tpanel.GitTools.Branch

  @doc """
  Returns the list of branches.

  ## Examples

      iex> list_branches()
      [%Branch{}, ...]

  """
  def list_branches do
    Repo.all(Branch)
  end

  @doc """
  Gets a single branch.

  Raises `Ecto.NoResultsError` if the Branch does not exist.

  ## Examples

      iex> get_branch!(123)
      %Branch{}

      iex> get_branch!(456)
      ** (Ecto.NoResultsError)

  """
  def get_branch!(id), do: Repo.get!(Branch, id)

  @doc """
  Creates a branch.

  ## Examples

      iex> create_branch(%{field: value})
      {:ok, %Branch{}}

      iex> create_branch(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_branch(attrs \\ %{}) do
    %Branch{}
    |> Branch.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a branch.

  ## Examples

      iex> update_branch(branch, %{field: new_value})
      {:ok, %Branch{}}

      iex> update_branch(branch, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_branch(%Branch{} = branch, attrs) do
    branch
    |> Branch.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a branch.

  ## Examples

      iex> delete_branch(branch)
      {:ok, %Branch{}}

      iex> delete_branch(branch)
      {:error, %Ecto.Changeset{}}

  """
  def delete_branch(%Branch{} = branch) do
    Repo.delete(branch)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking branch changes.

  ## Examples

      iex> change_branch(branch)
      %Ecto.Changeset{data: %Branch{}}

  """
  def change_branch(%Branch{} = branch, attrs \\ %{}) do
    Branch.changeset(branch, attrs)
  end

  def default_rev(%Branch{} = branch) do
    if is_nil(branch.target_revision) or String.length(branch.target_revision) == 0 do
      branch.fetched_revision
    else
      branch.target_revision
    end
  end

  alias Tpanel.GitTools.TestMix

  @doc """
  Returns the list of testmixes.

  ## Examples

      iex> list_testmixes()
      [%TestMix{}, ...]

  """
  def list_testmixes do
    Repo.all(TestMix)
  end

  @doc """
  Gets a single test_mix.

  Raises `Ecto.NoResultsError` if the Test mix does not exist.

  ## Examples

      iex> get_test_mix!(123)
      %TestMix{}

      iex> get_test_mix!(456)
      ** (Ecto.NoResultsError)

  """
  def get_test_mix!(id), do: Repo.get!(TestMix, id)

  @doc """
    Returns a test_mix with all associated branches data preloaded
  """
  def get_full_test_mix!(id) do
    get_test_mix!(id) 
    |> Repo.preload([branches: from(branch in Tpanel.GitTools.Branch, order_by: [desc: :priority])])
  end

  @doc """
  Creates a test_mix.

  ## Examples

      iex> create_test_mix(%{field: value})
      {:ok, %TestMix{}}

      iex> create_test_mix(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_test_mix(attrs \\ %{}) do
    %TestMix{}
    |> TestMix.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a test_mix.

  ## Examples

      iex> update_test_mix(test_mix, %{field: new_value})
      {:ok, %TestMix{}}

      iex> update_test_mix(test_mix, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_test_mix(%TestMix{} = test_mix, attrs) do
    test_mix
    |> TestMix.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a test_mix.

  ## Examples

      iex> delete_test_mix(test_mix)
      {:ok, %TestMix{}}

      iex> delete_test_mix(test_mix)
      {:error, %Ecto.Changeset{}}

  """
  def delete_test_mix(%TestMix{} = test_mix) do
    Repo.delete(test_mix)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking test_mix changes.

  ## Examples

      iex> change_test_mix(test_mix)
      %Ecto.Changeset{data: %TestMix{}}

  """
  def change_test_mix(%TestMix{} = test_mix, attrs \\%{}) do
    TestMix.changeset(test_mix, attrs)
  end

  @doc """
  Create a branch for a TestMix
  """ 
  def create_mix_branch(%TestMix{} = test_mix, attrs) do
    Ecto.build_assoc(test_mix, :branches)
    |> Branch.changeset(attrs)
    |> Repo.insert()
  end
end
