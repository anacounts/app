defmodule App.Books.BookMember do
  @moduledoc """
  The link between a book and a user.
  It contains the role of the user for this particular book.
  """
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query

  alias App.Accounts.User
  alias App.Balance.BalanceConfig
  alias App.Books.Book
  alias App.Books.InvitationToken
  alias App.Books.Role

  @type id :: integer()

  @type t :: %__MODULE__{
          id: id(),
          book_id: Book.id(),
          book: Book.t(),
          role: Role.t(),
          user_id: User.id() | nil,
          user: User.t() | nil,
          invitation_sent: boolean(),
          deleted_at: NaiveDateTime.t(),
          nickname: String.t(),
          display_name: String.t() | nil,
          email: String.t() | nil,
          balance_config: BalanceConfig.t() | nil,
          balance_config_id: BalanceConfig.id() | nil,
          balance: Money.t() | {:error, reasons :: [String.t()]} | nil,
          inserted_at: NaiveDateTime.t(),
          updated_at: NaiveDateTime.t()
        }

  schema "book_members" do
    belongs_to :book, Book
    field :role, Ecto.Enum, values: Role.all()

    belongs_to :user, User
    field :invitation_sent, :boolean, virtual: true

    field :deleted_at, :naive_datetime

    # When the member is not linked to a user, the display name falls back to the book
    # member's `:nickname`, set at creation
    field :nickname, :string

    # Filled with the user `:display_name` if there is one, otherwise `:nickname`
    field :display_name, :string, virtual: true
    # Filled with the user `:email` if there is one
    field :email, :string, virtual: true

    # the current balance configuration for this member
    belongs_to :balance_config, BalanceConfig
    # Filled by the `Balance` context. Maybe be set to `{:error, reasons}` if the
    # balance cannot be computed.
    field :balance, Money.Ecto.Composite.Type, virtual: true

    timestamps()
  end

  ## Changeset

  def changeset(struct, attrs) do
    struct
    |> cast(attrs, [:user_id, :role, :nickname])
    |> validate_book_id()
    |> validate_user_id()
    |> validate_role()
    |> validate_nickname()
    |> unique_constraint([:book_id, :user_id],
      message: "user is already a member of this book",
      error_key: :user_id
    )
  end

  defp validate_book_id(changeset) do
    changeset
    |> validate_required(:book_id)
    |> foreign_key_constraint(:book_id)
  end

  defp validate_user_id(changeset) do
    changeset
    |> foreign_key_constraint(:user_id)
  end

  defp validate_role(changeset) do
    changeset
    |> validate_required(:role)
  end

  defp validate_nickname(changeset) do
    changeset
    |> validate_required(:nickname)
    |> validate_length(:nickname, min: 1, max: 255)
  end

  @doc """
  Changeset for updating the balance config of a book member.
  """
  @spec balance_config_changeset(t(), map()) :: Ecto.Changeset.t()
  def balance_config_changeset(struct, attrs) do
    struct
    |> cast(attrs, [:balance_config_id])
    |> validate_balance_config_id()
  end

  defp validate_balance_config_id(changeset) do
    changeset
    |> foreign_key_constraint(:balance_config_id)
  end

  ## Queries

  @doc """
  Returns an `%Ecto.Query{}` fetching all book members.
  """
  def base_query do
    from __MODULE__, as: :book_member
  end

  @doc """
  Updates an `%Ecto.Query{}` to select the `:invitation_sent` field of book members.
  """
  @spec select_invitation_sent(Ecto.Query.t()) :: Ecto.Query.t()
  def select_invitation_sent(query) do
    from [book_member: book_member] in query,
      select_merge: %{
        invitation_sent:
          exists(
            from invitation_token in InvitationToken,
              where: invitation_token.book_member_id == parent_as(:book_member).id
          )
      }
  end

  @doc """
  Updates an `%Ecto.Query{}` to select the `:display_name` of book members.
  """
  @spec select_display_name(Ecto.Query.t()) :: Ecto.Query.t()
  def select_display_name(query) do
    from [book_member: book_member, user: user] in join_user(query),
      select_merge: %{display_name: coalesce(user.display_name, book_member.nickname)}
  end

  @doc """
  Updates an `%Ecto.Query{}` to select the `:email` of book members.
  """
  @spec select_email(Ecto.Query.t()) :: Ecto.Query.t()
  def select_email(query) do
    from [user: user] in join_user(query),
      select_merge: %{email: user.email}
  end

  defp join_user(query) do
    with_named_binding(query, :user, fn query ->
      from [book_member: book_member] in query,
        left_join: user in assoc(book_member, :user),
        as: :user
    end)
  end
end
