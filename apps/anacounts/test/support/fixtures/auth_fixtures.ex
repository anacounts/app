defmodule Anacounts.AuthFixtures do
  def unique_user_email, do: "user#{System.unique_integer()}@example.com"
  def valid_user_password, do: "hello world!"

  def valid_user_attributes(attrs \\ %{}) do
    Enum.into(attrs, %{
      email: unique_user_email(),
      password: valid_user_password()
    })
  end

  def user_fixture(attrs \\ %{}) do
    {:ok, user} =
      attrs
      |> valid_user_attributes()
      |> Anacounts.Auth.register_user()

    user
  end

  def setup_user_fixture(context) do
    Map.put(context, :user, user_fixture())
  end
end
