defmodule Anacounts.Mailer do
  @moduledoc """
  Send emails from the app.
  """

  use Swoosh.Mailer, otp_app: :anacounts
end
