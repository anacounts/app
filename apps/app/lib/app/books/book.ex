defmodule App.Books.Book do
  @moduledoc """
  The entity grouping users and transfers.
  """

  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query

  alias App.Balance.TransferParams

  @type id :: integer()
  @type t :: %__MODULE__{
          id: id(),
          name: String.t(),
          closed_at: NaiveDateTime.t() | nil,
          deleted_at: NaiveDateTime.t(),
          default_balance_params: TransferParams.t(),
          inserted_at: NaiveDateTime.t(),
          updated_at: NaiveDateTime.t()
        }

  schema "books" do
    field :name, :string
    field :closed_at, :naive_datetime
    field :deleted_at, :naive_datetime

    # balance
    field :default_balance_params, TransferParams

    timestamps()
  end

  ## Changeset

  def changeset(struct, attrs) do
    struct
    |> cast(attrs, [:name, :default_balance_params])
    |> validate_name()
    |> validate_default_balance_params()
  end

  defp validate_name(changeset) do
    changeset
    |> validate_required(:name)
    |> validate_length(:name, max: 255)
  end

  defp validate_default_balance_params(changeset) do
    changeset
    |> validate_required(:default_balance_params)
  end

  @doc """
  Returns a changeset to close a book.
  """
  @spec close_changeset(t()) :: Ecto.Changeset.t()
  def close_changeset(book) do
    now = NaiveDateTime.utc_now(:second)
    change(book, closed_at: now)
  end

  @doc """
  Returns a changeset to re-open a book.
  """
  @spec reopen_changeset(t()) :: Ecto.Changeset.t()
  def reopen_changeset(book) do
    change(book, closed_at: nil)
  end

  @doc """
  Returns a changeset to soft-delete a book.
  """
  @spec delete_changeset(t()) :: Ecto.Changeset.t()
  def delete_changeset(book) do
    now = NaiveDateTime.utc_now(:second)
    change(book, deleted_at: now)
  end

  ## Queries

  @spec base_query() :: Ecto.Query.t()
  def base_query do
    from book in __MODULE__,
      as: :book,
      where: is_nil(book.deleted_at)
  end
end
