defmodule App.AuthFixtures do
  @moduledoc """
  Fixtures for the `App.Auth` context
  """

  alias App.Auth

  def unique_user_email, do: "user#{System.unique_integer()}@example.com"

  def user_attributes(attrs \\ %{}) do
    Enum.into(attrs, %{
      email: unique_user_email(),
      password: "hello world!",
      display_name: "Test User"
    })
  end

  def user_fixture(attrs \\ %{}) do
    {:ok, user} =
      attrs
      |> user_attributes()
      |> Auth.register_user()

    user
  end

  def extract_user_token(fun) do
    {:ok, captured_email} = fun.(&"[TOKEN]#{&1}[TOKEN]")
    [_, token | _] = String.split(captured_email.text_body, "[TOKEN]")
    token
  end
end
