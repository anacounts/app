defmodule App.Books.InvitationToken do
  @moduledoc """
  Tokens used to invite a user to a book. They are linked to a BookMember.
  """

  use Ecto.Schema
  import Ecto.Query

  alias App.Books.BookMember

  @hash_algorithm :sha256
  @rand_size 16

  schema "invitation_tokens" do
    field :token, :binary
    field :sent_to, :string
    belongs_to :book_member, BookMember

    timestamps(updated_at: false)
  end

  @doc """
  Builds a token and its hash to be delivered to the user's email.

  The non-hashed token is sent to the user email while the
  hashed part is stored in the database. The original token cannot be reconstructed,
  which means anyone with read-only access to the database cannot directly use
  the token in the application to gain access. Furthermore, if the user changes
  their email in the system, the tokens sent to the previous email are no longer
  valid.

  Users can easily adapt the existing code to provide other types of delivery methods,
  for example, by phone numbers.
  """
  def build_invitation_token(%BookMember{} = book_member, sent_to) when is_binary(sent_to) do
    token = :crypto.strong_rand_bytes(@rand_size)
    hashed_token = :crypto.hash(@hash_algorithm, token)

    {Base.url_encode64(token, padding: false),
     %__MODULE__{
       token: hashed_token,
       sent_to: sent_to,
       book_member_id: book_member.id
     }}
  end

  @doc """
  Checks if the token is valid and returns its underlying lookup query.

  The query returns the book member found by the token, if any.

  The given token is valid if it matches its hashed counterpart in the
  database and the user email has not changed.
  """
  def verify_invitation_token_query(token, user) do
    case Base.url_decode64(token, padding: false) do
      {:ok, decoded_token} ->
        hashed_token = :crypto.hash(@hash_algorithm, decoded_token)

        query =
          from token in token_query(hashed_token),
            join: book_member in assoc(token, :book_member),
            where: token.sent_to == ^user.email,
            select: book_member

        {:ok, query}

      :error ->
        :error
    end
  end

  defp token_query(token) do
    from __MODULE__, where: [token: ^token]
  end
end
