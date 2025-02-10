defmodule App.Balance.CacheUpdaterWorker do
  @moduledoc """
  An Oban job that updates the balance of book members within a book.
  """
  use Oban.Worker,
    queue: :balance,
    max_attempts: 1,
    unique: [
      fields: [:args],
      keys: [:book_id],
      states: [:available, :scheduled, :executing, :retryable]
    ]

  alias App.Balance
  alias App.Books
  alias App.Books.Book

  @doc """
  Create a new job to update the balance of book members.

  If a job is already scheduled for the book, it will be replaced.
  """
  @spec update_book_balance(Book.id()) :: {:ok, Oban.Job.t()} | {:error, term()}
  def update_book_balance(book_id) when is_integer(book_id) do
    %{book_id: book_id}
    |> new()
    |> Oban.insert()
  end

  @impl Oban.Worker
  def perform(job) do
    %{"book_id" => book_id} = job.args

    book_id
    |> Books.get_book!()
    |> Balance.update_book_members_balance()
  end
end
