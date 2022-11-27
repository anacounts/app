defmodule App.Books.MemberNotifier do
  @moduledoc """
  Send emails for books related operations.

  Can send invitations.
  """

  import Swoosh.Email

  alias App.Mailer

  # Delivers the email using the application mailer.
  defp deliver(recipient, subject, body) do
    email =
      new()
      |> to(recipient)
      |> from({"Anacounts", Mailer.no_reply_email()})
      |> subject(subject)
      |> text_body(body)

    with {:ok, _metadata} <- Mailer.deliver(email) do
      {:ok, email}
    end
  end

  @doc """
  Deliver book invitations.
  """
  def deliver_invitation(email, url) do
    deliver(email, "You've been invited to a new book !", """

    ==============================

    Hi,

    Someone invited you to join a new book on Anacounts.
    You can join it by clicking on the following link:

    #{url}

    If you don't have an account yet, you will be asked to create one first.

    ==============================
    """)
  end
end
