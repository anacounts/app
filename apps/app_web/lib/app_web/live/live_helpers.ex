defmodule AppWeb.LiveHelpers do
  @moduledoc """
  A module defining complex components for live views.

  The components defined here are based on the components defined in
  `AppWeb.ComponentHelpers`. They are more complex and usually only fit
  in more specific contexts.
  """

  import Phoenix.Component

  import AppWeb.Gettext
  import AppWeb.ComponentHelpers

  ## Page header

  @doc """
  Generates the base header.

  ## Options

  - :back_to - The path to link to for the back button.
    Defaults to nil and does not display the back button.

  ## Slots

  - :menu - The menu to use
  - default - The content in place of the title

  ## Examples

      <.page_header back_to="#">
        <:title>Anacounts</:title>

        <:menu>
          <.dropdown id="contextual-menu">
            <:toggle>
              <.icon name="dots-vertical" alt={gettext("Contextual menu")} size={:lg} />
            </:toggle>

            <.list_item_link navigate="/users/settings">
              <.icon name="cog" />
              Settings
            </.list_item_link>
            <.list_item_link href="/users/log_out" method="delete">
              <.icon name="out" />
              Disconnect
            </.list_item_link>
          </.dropdown>
        </:menu>
      </.page_header>

  """
  def page_header(assigns) do
    ~H"""
    <header class="flex items-center gap-2
                   h-16
                   mx-4">
      <.link :if={assigns[:back_to]} navigate={@back_to} class="button button--invisible">
        <.icon name="arrow-left" alt={gettext("Go back")} />
      </.link>
      <.heading level="title" class="mr-auto"><%= render_slot(@title) %></.heading>
      <%= if assigns[:menu] do %>
        <%= render_slot(@menu) %>
      <% end %>
    </header>
    """
  end
end
