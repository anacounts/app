defmodule App.Books.Book do
  @moduledoc """
  The entity grouping users and transfers.
  """

  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query

  alias App.Auth
  alias App.Balance
  alias App.Books.Members.BookMember

  @type id :: integer()
  @type t :: %__MODULE__{
          id: id(),
          name: String.t(),
          deleted_at: NaiveDateTime.t(),
          members: [BookMember.t()],
          users: [Auth.User.t()],
          default_balance_params: Balance.TransferParams.t(),
          inserted_at: NaiveDateTime.t(),
          updated_at: NaiveDateTime.t()
        }

  schema "books" do
    field :name, :string
    field :deleted_at, :naive_datetime

    # user relation
    has_many :members, BookMember
    many_to_many :users, Auth.User, join_through: BookMember

    # balance
    field :default_balance_params, Balance.TransferParams

    timestamps()
  end

  ## Changeset

  # TODO drop create changesets

  @doc """
  A book changeset for creation.
  The user given will be considered the first member and creator of the book.
  """
  def create_changeset(struct, user, attrs) do
    struct
    |> changeset(attrs)
    |> put_creator(user)
  end

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

  defp put_creator(changeset, creator) do
    changeset
    |> put_change(:members, [
      %{
        user: creator,
        role: :creator
      }
    ])
  end

  def delete_changeset(book) do
    now = NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)
    change(book, deleted_at: now)
  end

  ## Query

  @spec base_query :: Ecto.Query.t()
  def base_query do
    from book in __MODULE__,
      as: :book,
      where: is_nil(book.deleted_at)
  end

  def join_members(query) do
    if has_named_binding?(query, :member) do
      query
    else
      from [book: book] in query,
        join: assoc(book, :members),
        as: :member
    end
  end

  def join_users(query) do
    if has_named_binding?(query, :user) do
      query
    else
      from [book: book] in query,
        join: assoc(book, :users),
        as: :user
    end
  end

  # TODO drop

  @spec user_query(Auth.User.t()) :: Ecto.Query.t()
  def user_query(%{id: user_id}) do
    base_query()
    |> join_users()
    |> where([user: user], user.id == ^user_id)
  end
end
