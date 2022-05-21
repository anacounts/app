defmodule Anacounts.Accounts.Book do
  @moduledoc """
  The entity grouping users and transfers.
  """

  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query

  alias Anacounts.Accounts
  alias Anacounts.Auth

  @type id :: integer()
  @type t :: %__MODULE__{
          id: id(),
          name: String.t(),
          deleted_at: NaiveDateTime.t(),
          members: [Accounts.BookMember.t()],
          users: [Auth.User.t()],
          inserted_at: NaiveDateTime.t(),
          updated_at: NaiveDateTime.t()
        }

  schema "accounts_books" do
    field :name, :string
    field :deleted_at, :naive_datetime

    # user relation
    has_many :members, Accounts.BookMember
    many_to_many :users, Auth.User, join_through: Accounts.BookMember

    timestamps()
  end

  @doc """
  A book changeset for creation.
  The user given will be considered the first member and creator of the book.
  """
  def creation_changeset(book, user, attrs) do
    book
    |> cast(attrs, [:name])
    |> validate_name()
    |> put_creator(user)
  end

  defp validate_name(changeset) do
    changeset
    |> validate_required([:name])
    |> validate_length(:name, max: 255)
  end

  defp put_creator(changeset, creator) do
    changeset
    |> put_change(:members, [
      %{
        user: creator,
        role: :creator
      }
    ])
  end

  @spec base_query :: Ecto.Query.t()
  def base_query do
    from b in __MODULE__, where: is_nil(b.deleted_at)
  end

  @spec user_query(Auth.User.t()) :: Ecto.Query.t()
  def user_query(user) do
    from b in base_query(),
      join: u in assoc(b, :users),
      on: u.id == ^user.id
  end
end
