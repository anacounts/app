defmodule AppWeb.PageComponents do
  @moduledoc """
  A module defining complex components for live views.

  The components defined here are based on the components defined in
  `AppWeb.CoreComponents`. They are more complex and usually only fit
  in more specific contexts.
  """

  use Phoenix.Component

  import Phoenix.HTML, only: [raw: 1]

  import AppWeb.Gettext
  import AppWeb.CoreComponents

  alias Phoenix.LiveView.JS

  ## Page header

  @doc """
  Generates the base header.

  [INSERT LVATTRDOCS]

  ## Examples

      <.page_header back_to="#">
        <:title>Anacounts</:title>

        <:menu>
          <.dropdown id="contextual-menu">
            <:toggle>
              <.icon name="more-vert" alt={gettext("Contextual menu")} size={:lg} />
            </:toggle>

            <:tab_item navigate="/tab_one">
              <.icon name="account" size={:md} />
              Go to tab one
            </:tab_item>
            <:tab_item navigate="/tab_two">
              <.icon name="add" size={:md} />
              Go to tab two
            </:tab_item>

            <.list_item_link navigate="/users/settings">
              <.icon name="settings" />
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
                   h-14 mb-2 px-4
                   bg-theme text-white shadow">
      <.link :if={assigns[:back_to]} navigate={@back_to} class="button button--ghost">
        <.icon name="arrow-back" alt={gettext("Go back")} />
      </.link>

      <.heading level={:title} class="mr-auto"><%= render_slot(@title) %></.heading>

      <.tabs :if={not is_nil(assigns[:tab_item]) and not Enum.empty?(@tab_item)}>
        <:item :for={tab_item <- @tab_item} {assigns_to_attributes(tab_item)}>
          <%= render_slot(tab_item) %>
        </:item>
      </.tabs>

      <%= render_slot(assigns[:menu] || []) %>
    </header>
    """
  end

  ## Panel group

  @doc """
  Renders a group of panels, with only one panel visible at a time on smaller screens.
  On large screens, panels are aligned side by side as long as they fit in the container.

  Panels must have an `id` attribute, and can have an `active` attribute to indicate
  which panel is currently visible. Only one panel must be active at a time.
  To switch the active panel, the `:panel` slot is render with a function as argument
  that, when called with the `id` of the panel to show, will hide the active panel
  and show the panel with the given `id`.

  ## Examples

      <.panel_group class="mb-4">
        <:panel :let={show_panel} id="panel-1" active>
          <button phx-click={show_panel.("panel-2")}>Show panel 2</button>
        </:panel>
        <:panel :let={show_panel} id="panel-2">
          <button phx-click={show_panel.("panel-1")}>Show panel 1</button>
        </:panel>
      </.panel_group>

  """

  attr :class, :any, default: nil
  attr :rest, :global

  slot :panel do
    attr :id, :string, required: true
    attr :active, :boolean
  end

  def panel_group(assigns) do
    ~H"""
    <div class={["panel-group", @class]}>
      <section
        :for={panel <- @panel}
        id={panel[:id]}
        class={["panel-group__panel", panel_group_active_class(panel[:active])]}
      >
        <%= render_slot(panel, show_panel_command()) %>
      </section>
    </div>
    """
  end

  defp panel_group_active_class(true), do: "panel-group__panel--active"
  defp panel_group_active_class(_), do: nil

  defp show_panel_command do
    fn panel_id ->
      JS.dispatch("panel_group:show", detail: panel_id)
    end
  end

  ## Markdown

  @doc """
  Renders a Markdown string in HTML. The [`typography`](https://tailwindcss.com/docs/typography-plugin)
  plugin of TailwindCSS is used to style the renderd HTML, along with its `.prose` class.

  The markdown is expected to be valid, otherwise the component will crash.

  ## Attributes

  - :content - The markdown content to display.

  ## Examples

      <.markdown content={@content} />

  """
  def markdown(assigns) do
    {:ok, rendered, []} = Earmark.as_html(assigns.content, compact_output: true)

    assigns = assign(assigns, :rendered, rendered)

    ~H"""
    <div class="prose">
      <%= raw(@rendered) %>
    </div>
    """
  end
end
