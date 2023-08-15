defmodule App.Books.Members do
  @moduledoc """
  The Books.Members context.
  """

  import Ecto.Query
  alias App.Repo

  alias App.Accounts.User
  alias App.Balance.BalanceConfig
  alias App.Balance.BalanceConfigs
  alias App.Books
  alias App.Books.Book
  alias App.Books.BookMember
  alias App.Books.InvitationToken
  alias App.Books.MemberNotifier

  @doc """
  Lists all members of a book.

  ## Examples

      iex> list_members_of_book(book)
      [%BookMember{}, ...]

  """
  @spec list_members_of_book(Book.t()) :: [BookMember.t()]
  def list_members_of_book(%Book{} = book) do
    members_of_book_query(book)
    |> Repo.all()
  end

  defp members_of_book_query(book) do
    from([book_member: book_member] in base_query(),
      left_join: user in assoc(book_member, :user),
      where: book_member.book_id == ^book.id,
      order_by: [asc: coalesce(user.display_name, book_member.nickname)]
    )
    |> with_display_name_query()
    |> with_email_query()
  end

  @doc """
  Gets a single book_member.

  Raises `Ecto.NoResultsError` if the Book member does not exist.

  ## Examples

      iex> get_book_member!(123)
      %BookMember{}

      iex> get_book_member!(456)
      ** (Ecto.NoResultsError)

  """
  def get_book_member!(id) do
    base_query()
    |> with_display_name_query()
    |> Repo.get!(id)
  end

  @doc """
  Get the book member entity linking a user to a book.

  Returns `nil` if the user is not a member of the book.

  ## Examples

      iex> get_book_member_of_user(book.id, user.id)
      %BookMember{}

      iex> get_book_member_of_user(book.id, non_member_user.id)
      nil

  """
  # TODO use entities instead of ids
  @spec get_membership(Book.id(), User.id()) :: BookMember.t() | nil
  def get_membership(book_id, user_id) do
    Repo.get_by(BookMember, book_id: book_id, user_id: user_id)
  end

  @doc """
  Get the book member entity linking a user to a book.

  Raises `Ecto.NoResultsError` if the user is not a member of the book.

  ## Examples

      iex> get_book_member_of_user!(book.id, user.id)
      %BookMember{}

      iex> get_book_member_of_user!(book.id, non_member_user.id)
      ** (Ecto.NoResultsError)

  """
  @spec get_membership!(Book.t(), User.t()) :: BookMember.t() | nil
  def get_membership!(%Book{} = book, %User{} = user) do
    Repo.get_by(BookMember, book_id: book.id, user_id: user.id)
  end

  @doc """
  Get the book member linked to an invitation token. Returns `nil` if the token is
  invalid, not found, or if the user email does not match the email the token was
  sent to.

  ## Examples

      iex> get_book_member_of_invitation_token(token, user)
      %BookMember{}

      iex> get_book_member_of_invitation_token(invalid_token, user)
      nil

      iex> get_book_member_of_invitation_token(token, user_the_token_was_not_sent_to)
      nil

  """
  @spec get_book_member_by_invitation_token(String.t(), User.t()) :: BookMember.t() | nil
  def get_book_member_by_invitation_token(token, %User{} = user) do
    case InvitationToken.verify_invitation_token_query(token, user) do
      {:ok, query} -> Repo.one(query)
      :error -> nil
    end
  end

  @doc """
  Check if a book member is linked to a user.

  ## Examples

      iex> independent?(book_member)
      true

      iex> independent?(book_member_with_user)
      false

  """
  @spec independent?(BookMember.t()) :: boolean()
  def independent?(%BookMember{} = book_member) do
    book_member.user_id == nil
  end

  @doc """
  Create a new book member within a book.

  # Examples

        iex> create_book_member(book, %{nickname: "John Doe", role: :member})
        {:ok, %BookMember{}}

        iex> create_book_member(book, %{nickname: nil, role: :unknown})
        {:error, %Ecto.Changeset{}}

  """
  @spec create_book_member(Book.t(), map()) ::
          {:ok, BookMember.t()} | {:error, Ecto.Changeset.t()}
  def create_book_member(%Book{} = book, attrs) do
    %BookMember{book_id: book.id}
    # set the member role as default, it can be changed later
    |> BookMember.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Deliver an invitation to a user to join a book as a existing member. This is the most
  common way to invite a user to a book, which allows to create book members without them
  being linked to an existing user yet.

  ## Examples

      iex> deliver_invitation(book_member, user, &"/invitation/\#{&1}")
      {:ok, email}

      iex> deliver_invitation(%{user_id: 1} = book_member, user, &"/invitation/\#{&1}")
      ** (ArgumentError)

  """
  @spec deliver_invitation(BookMember.t(), String.t(), (String.t() -> String.t())) ::
          {:ok, Swoosh.Email.t()}
  def deliver_invitation(%BookMember{user_id: nil} = member, email, sent_invite_url_fun)
      when is_function(sent_invite_url_fun, 1) do
    book = Books.get_book!(member.book_id)
    {hashed_token, invitation_token} = InvitationToken.build_invitation_token(member, email)

    Repo.insert!(invitation_token)
    MemberNotifier.deliver_invitation(email, book.name, sent_invite_url_fun.(hashed_token))
  end

  @doc """
  Accept an invitation to join a book. The first parameter is the book member that will
  get updated, the second is the user accepting the invitation.

  This will link the book member to the user. The function raises if the book member is
  already linked to a user.

  ## Examples

      iex> accept_invitation(book_member, user)
      {:ok, %BookMember{}}

      iex> accept_invitation(%{user_id: 1} = book_member, user)
      ** (FunctionClauseError)

  """
  @spec accept_invitation(BookMember.t(), User.t()) :: {:ok, BookMember.t()}
  def accept_invitation(%BookMember{user_id: nil} = book_member, %User{} = user) do
    {:ok, %{book_member: book_member}} =
      Ecto.Multi.new()
      |> Ecto.Multi.update(:book_member, BookMember.changeset(book_member, %{user_id: user.id}))
      |> link_user_balance_configs_multi(user)
      |> maybe_try_to_delete_balance_config_multi(book_member.balance_config_id)
      |> Ecto.Multi.delete_all(
        :invitation_tokens,
        InvitationToken.book_member_tokens_query(book_member)
      )
      |> Repo.transaction()

    {:ok, book_member}
  end

  defp link_user_balance_configs_multi(multi, user) do
    Ecto.Multi.run(multi, :balance_config, fn _repo, %{book_member: book_member} ->
      BalanceConfigs.link_user_balance_configs_to_member!(user, book_member)
      {:ok, nil}
    end)
  end

  defp maybe_try_to_delete_balance_config_multi(multi, nil), do: multi

  defp maybe_try_to_delete_balance_config_multi(multi, balance_config_id) do
    Ecto.Multi.run(multi, :delete_balance_config, fn _repo, _changes ->
      balance_config = %BalanceConfig{id: balance_config_id}
      BalanceConfigs.try_to_delete_balance_config(balance_config)
      {:ok, nil}
    end)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking book member changes.

  ## Examples

      iex> change_book_member(book_member)
      %Ecto.Changeset{data: %BookMember{}}

  """
  @spec change_book_member(BookMember.t(), map()) :: Ecto.Changeset.t(BookMember.t())
  def change_book_member(book_member, attrs \\ %{}) do
    BookMember.changeset(book_member, attrs)
  end

  ## Queries

  @doc """
  Returns an `%Ecto.Query{}` for fetching all book members.

  Combine with `with_display_name_query/1` to query the display name of the book member
  along the way.

  ## Examples

      iex> base_query()
      #Ecto.Query<from b0 in App.Books.BookMember, as: :book_member>

      iex> Repo.all(base_query())
      [%BookMember{}, ...]

  """
  def base_query do
    from BookMember, as: :book_member
  end

  @doc """
  Updates an `%Ecto.Query{}` to query the display name of the book members along the way.

  ## Examples

      iex> base_query() |> with_display_name_query()
      #Ecto.Query<from b0 in App.Books.BookMember, as: :book_member,
        left_join: u1 in assoc(b0, :user), as: :user,
        select: merge(b0, %{display_name: coalesce(u1.display_name, b0.nickname)})>

      iex> base_query() |> with_display_name_query() |> Repo.all()
      [%BookMember{display_name: "John Doe"}, ...]

  """
  def with_display_name_query(query) do
    from [book_member: book_member, user: user] in join_user(query),
      select_merge: %{display_name: coalesce(user.display_name, book_member.nickname)}
  end

  # Load the `:email` virtual field. Only works if querying BookMember entities.
  defp with_email_query(query) do
    from [user: user] in join_user(query),
      select_merge: %{email: user.email}
  end

  def where_user_id(query, user_id) do
    from [book_member: book_member] in query,
      where: book_member.user_id == ^user_id
  end

  def join_user(query, qual \\ :left) do
    with_named_binding(query, :user, fn query ->
      join(query, qual, [book_member: book_member], assoc(book_member, :user), as: :user)
    end)
  end
end
