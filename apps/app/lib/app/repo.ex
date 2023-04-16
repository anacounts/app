defmodule App.Repo do
  use Ecto.Repo,
    otp_app: :app,
    adapter: Ecto.Adapters.Postgres

  @doc """
  Create a savepoint and execute the given function in a transaction.
  If the function raises, the transaction is rolled back to the savepoint.
  If the function succeeds, the savepoint is released.

  ## Examples

      iex> savepoint(fn ->
      ...>   insert(%User{name: "John"})
      ...>   insert(%User{name: "Jane"})
      ...> end)
      {:ok, %Postgrex.Result{}}

      iex> savepoint(fn ->
      ...>   insert(%User{name: "John"})
      ...>   insert(%User{name: "John"})
      ...> end)
      {:error, %Postgrex.Error{}}

  """
  def savepoint(func) when is_function(func, 0) do
    name = "SP#{System.unique_integer([:positive])}"
    create_savepoint(name)

    try do
      func.()
    rescue
      Postgrex.Error ->
        rollback_to_savepoint(name)
    after
      release_savepoint(name)
    end
  end

  # Create a savepoint
  @spec create_savepoint(String.t() | atom()) :: term()
  defp create_savepoint(name) do
    query!("SAVEPOINT #{name}")
  end

  # Rollback to a savepoint
  @spec rollback_to_savepoint(String.t() | atom()) :: term()
  defp rollback_to_savepoint(name) do
    query!("ROLLBACK TO SAVEPOINT #{name}")
  end

  # Release a savepoint
  @spec release_savepoint(String.t() | atom()) :: term()
  defp release_savepoint(name) do
    query!("RELEASE SAVEPOINT #{name}")
  end
end
