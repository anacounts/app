defmodule AnacountsAPI.Schema.AccountsTypes do
  @moduledoc """
  Objects related to the `Anacounts.Account` module.
  """

  use Absinthe.Schema.Notation

  alias AnacountsAPI.Resolvers

  ## Entities

  @desc "A group of people"
  object :book do
    field(:id, :id)
    field(:name, :string)
    field(:inserted_at, :naive_datetime)

    field(:members, list_of(:book_member)) do
      resolve(&Resolvers.Auth.find_book_members/3)
    end
  end

  @desc "One of the users attached to a book"
  object :book_member do
    interface(:base_user)
    is_type_of(&match?(%{role: _}, &1))

    field(:id, :id)
    field(:email, :string)
    field(:role, :string)
  end

  ## Queries

  object :accounts_queries do
    @desc "Get a book belonging to authentified user"
    field :book, :book do
      arg(:id, non_null(:id))

      resolve(&Resolvers.Accounts.find_book/3)
    end

    @desc "Get all books belonging to authentified user"
    field :books, list_of(:book) do
      resolve(&Resolvers.Accounts.find_books/3)
    end
  end

  ## Mutations

  object :accounts_mutations do
    field :create_book, :book do
      arg(:attrs, non_null(:book_input))

      resolve(&Resolvers.Accounts.do_create_book/3)
    end
  end

  ## Input objects

  @desc "Used to make operations (insert, update) on books"
  input_object :book_input do
    field(:name, non_null(:string))
  end
end
