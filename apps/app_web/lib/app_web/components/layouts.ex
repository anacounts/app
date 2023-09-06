defmodule AppWeb.Layouts do
  @moduledoc """
  Templates for application layouts.
  """
  use AppWeb, :html

  alias App.Accounts.Avatars

  embed_templates "layouts/*"
end
