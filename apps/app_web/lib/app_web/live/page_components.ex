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

  attr :back_to, :string, default: nil

  slot(:title, required: true)
  slot(:tab_item)
  slot(:menu)

  def page_header(assigns) do
    ~H"""
    <header class="flex items-center gap-2
                   h-14 mb-2 px-4
                   bg-theme text-white shadow">
      <.link :if={@back_to} navigate={@back_to} class="button button--ghost">
        <.icon name="arrow-back" alt={gettext("Go back")} />
      </.link>

      <.heading level={:title} class="mr-auto"><%= render_slot(@title) %></.heading>

      <.tabs :if={not Enum.empty?(@tab_item)}>
        <:item :for={tab_item <- @tab_item} {assigns_to_attributes(tab_item)}>
          <%= render_slot(tab_item) %>
        </:item>
      </.tabs>

      <%= render_slot(@menu) %>
    </header>
    """
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
