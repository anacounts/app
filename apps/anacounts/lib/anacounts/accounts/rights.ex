defmodule Anacounts.Accounts.Rights do
  @moduledoc """
  The ability to do some action on a book.
  Users have a role in their book with an associated role. This role
  defines their capacity to do or not to do some actions on the book.
  These capacities are represented by rights.
  """
  @type t :: atom()

  @all []
  def all, do: @all
end
