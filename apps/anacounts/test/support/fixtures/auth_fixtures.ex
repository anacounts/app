defmodule Anacounts.AuthFixtures do
  @moduledoc """
  Fixtures for the `Auth` context
  """

  def unique_user_email, do: "user#{System.unique_integer()}@example.com"
  def valid_user_password, do: "hello world!"

  def valid_user_attributes(attrs \\ %{}) do
    Enum.into(attrs, %{
      email: unique_user_email(),
      password: valid_user_password()
    })
  end

  def valid_register_attributes do
    %{
      email: unique_user_email(),
      password: valid_user_password()
    }
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

  def extract_user_token(fun) do
    {:ok, captured_email} = fun.(&"[TOKEN]#{&1}[TOKEN]")
    [_, token | _] = String.split(captured_email.text_body, "[TOKEN]")
    token
  end
end
