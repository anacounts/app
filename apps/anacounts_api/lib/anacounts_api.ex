defmodule AnacountsAPI do
  @moduledoc """
  The entrypoint for defining your router.

  This can be used in your application as:

      use AnacountsAPI, :router

  The definitions below will be executed for the router,
  so keep it short and clean, focused on imports, uses
  and aliases.

  Do NOT define functions inside the quoted expressions
  below. Instead, define any helper function in modules
  and import those modules here.
  """

  def router do
    quote do
      use Phoenix.Router

      import Plug.Conn
      import Phoenix.Controller
    end
  end

  @doc """
  When used, dispatch to the appropriate controller/view/etc.
  """
  defmacro __using__(which) when is_atom(which) do
    apply(__MODULE__, which, [])
  end
end
