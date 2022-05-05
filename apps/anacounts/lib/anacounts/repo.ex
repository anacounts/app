defmodule Anacounts.Repo do
  use Ecto.Repo,
    otp_app: :anacounts,
    adapter: Ecto.Adapters.Postgres
end
