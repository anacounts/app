defmodule App.Balance.BalanceConfig do
  @moduledoc """
  The balance configuration of a user or a book member. This includes private data,
  which is encrypted in the database.

  Each balance configuration is associated to either a user or a book member. When the
  configuration is associated to a user, it represents the default configuration for
  book members newly linked the user.

  # Lifecycle (book members' configuration)

  When a book member is created, a new empty balance configuration is created and
  associated to them. If a user is associated to the book member, the configuration is
  overriden with the user's default configuration.

  """
  use Ecto.Schema
  import Ecto.Changeset

  alias App.Auth.User
  alias App.Books.BookMember

  @type id :: integer()

  @type t :: %__MODULE__{
          id: id(),
          annual_income: non_neg_integer(),
          user: User.t() | nil,
          user_id: User.id() | nil,
          book_member: BookMember.t() | nil,
          book_member_id: BookMember.id() | nil
        }

  @derive {Inspect, only: [:id, :user, :user_id]}
  schema "balance_configs" do
    field :annual_income, App.Encrypted.Integer

    # a balance config is associated to either a user or a book member, but not both
    # see @moduledoc for more details
    belongs_to :user, User
    belongs_to :book_member, BookMember

    timestamps()
  end

  def changeset(struct, attrs) do
    struct
    |> cast(attrs, [:annual_income])
    |> validate_annual_income()
    |> validate_user_id()
    |> validate_book_member_id()
  end

  defp validate_annual_income(changeset) do
    changeset
    |> validate_number(:annual_income, greater_than_or_equal_to: 0)
  end

  defp validate_user_id(changeset) do
    changeset
    |> foreign_key_constraint(:user_id)
  end

  defp validate_book_member_id(changeset) do
    changeset
    |> foreign_key_constraint(:book_member_id)
  end
end
