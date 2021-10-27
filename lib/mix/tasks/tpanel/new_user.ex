defmodule Mix.Tasks.Tpanel.NewUser do
  @requirements ["app.start"]
  @moduledoc "Creates an user account manually"
  @shortdoc "Create user"
  use Mix.Task

  @impl Mix.Task
  def run(args) do
    input = Enum.at(args, 0)
    if String.length(input) do
      symbols = '0123456789abcdefghijklmnopqrstuvxyzABCDEFGHIJKLMNOPQRSTUVXYZ_@+-'
      symbol_count = Enum.count(symbols)
      pass = for _ <- 1..12, into: "", do: <<Enum.at(symbols, :rand.uniform(symbol_count)-1)>>
      Tpanel.Accounts.register_user(%{email: input, password: pass})
      |> case do
        {:ok, user} -> 
          IO.puts("Success! Password for #{user.email} : #{pass}")
        {:error, %Ecto.Changeset{} = changeset} ->
          IO.inspect changeset
      end
    else
      IO.puts("Please specify an email to create account for")
    end
  end
end
