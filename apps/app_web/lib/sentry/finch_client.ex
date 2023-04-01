defmodule Sentry.FinchClient do
  @moduledoc """
  Defines a small shim to use `Finch` as a `Sentry.HTTPClient`.

  Copied from https://claudio-ortolina.org/posts/using-finch-with-sentry/
  Referenced by issue: https://github.com/getsentry/sentry-elixir/issues/481
  """

  @behaviour Sentry.HTTPClient

  @impl Sentry.HTTPClient
  def child_spec do
    Finch.child_spec(name: Sentry.Finch)
  end

  @impl Sentry.HTTPClient
  def post(url, headers, body) do
    request = Finch.build(:post, url, headers, body)

    case Finch.request(request, Sentry.Finch) do
      {:ok, response} ->
        {:ok, response.status, response.headers, response.body}

      error ->
        error
    end
  end
end
