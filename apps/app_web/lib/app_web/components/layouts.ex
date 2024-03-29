defmodule AppWeb.Layouts do
  @moduledoc """
  Templates for application layouts.
  """
  use AppWeb, :html

  alias App.Accounts.Avatars
  alias App.Books

  embed_templates "layouts/*"
end
