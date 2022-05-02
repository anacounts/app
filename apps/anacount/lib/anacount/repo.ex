defmodule Anacount.Repo do
  use Ecto.Repo,
    otp_app: :anacount,
    adapter: Ecto.Adapters.Postgres
end
