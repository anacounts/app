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

  ## Filters

  @doc """
  Renders a filter dialog with sections.

  On desktop, the dialog is displayed at all times. On mobile, it
  can be toggled by calling `show_dialog/2` and selecting the filters id.

  ## Example

      <.filters id="filters">
        <:section icon="arrow_downward" title={gettext("Sort by")}>
          <.filter_options field={@filter_form[:sort_by]} options={sort_by_options()} />
        </:section>

        <:section icon="filter_alt" title={gettext("Filter by")}>
          <.filter_options field={@filter_form[:owned_by]} options={owned_by_options()} />
        </:section>
      </.filters>
  """
  attr :id, :string, required: true, doc: "the id of the filters container"
  attr :rest, :global

  slot :section, required: true do
    attr :icon, :string, required: true, doc: "the icon of the section"
    attr :title, :string, required: true, doc: "the title of the section"
  end

  def filters(assigns) do
    ~H"""
    <dialog
      id={@id}
      class="animate-fade-in backdrop:animate-backdrop-fade-in md:contents"
      phx-update="ignore"
    >
      <form
        class="fixed inset-0 top-auto md:static md:block w-full bg-white md:bg-transparent md:w-80 p-4 rounded-t-3xl animate-slide-in sm:animate-none"
        phx-click-away={hide_dialog("##{@id}")}
        {@rest}
      >
        <%= for section <- @section do %>
          <p class="block text-gray-80 mb-2">
            <.icon name={section.icon} class="h-5 fill-gray-70" />
            <%= section.title %>
          </p>
          <%= render_slot(section) %>
        <% end %>
      </form>
    </dialog>
    """
  end

  @doc """
  Renders a list of filter options.

  A `%Phoenix.HTML.Form{}` and field name may be passed to the options
  to build input names, value, and `checked` attribute or all the attributes
  may be passed explicitly.

  ## Examples

      <.filter_options field={@form[:sort_by]} options={[{"Title", "value"}]} />
      <.filter_options id="sort_by" name="sort_by" value="value" options={[{"Title", "value"]} />
  """
  attr :id, :any, default: nil
  attr :name, :any
  attr :value, :any

  attr :multiple, :boolean, default: false, doc: "whether multiple options can be selected"

  attr :field, Phoenix.Form.Field,
    doc: "a form field struct retrieved from the form, for example: @form[:email]"

  attr :options, :list, doc: "the list of options to display"

  def filter_options(%{field: %Phoenix.HTML.FormField{} = field} = assigns) do
    assigns
    |> assign(field: nil, id: assigns.id || field.id)
    |> assign_new(:name, fn -> if assigns.multiple, do: field.name <> "[]", else: field.name end)
    |> assign_new(:value, fn -> field.value end)
    |> filter_options()
  end

  def filter_options(assigns) do
    ~H"""
    <div class="mb-4">
      <label :for={{title, value} <- @options} class="inline-block m-1">
        <input
          type={if @multiple, do: "checkbox", else: "radio"}
          name={@name}
          value={value}
          checked={value == @value}
          class="peer hidden"
        />
        <span class="py-1 px-2 bg-background border border-gray-60 text-gray-80 peer-checked:bg-theme peer-checked:border-theme peer-checked:text-white rounded-full">
          <%= title %>
        </span>
      </label>
    </div>
    """
  end

  ## Page header

  @doc """
  Generates the base header.

  [INSERT LVATTRDOCS]

  ## Examples

      <.page_header hide_back>
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
    <header class="sticky top-0
                   flex items-center gap-2
                   h-14 mb-2 px-4
                   bg-theme text-white shadow">
      <.button
        :if={assigns[:hide_back] != true}
        color={:ghost}
        phx-click={JS.dispatch("app:navigate-back")}
      >
        <.icon name="arrow-back" alt={gettext("Go back")} />
      </.button>

      <b class="mr-auto text-xl md:text-2xl font-normal uppercase">
        <%= render_slot(@title) %>
      </b>

      <.tabs :if={not is_nil(assigns[:tab_item]) and not Enum.empty?(@tab_item)}>
        <:item :for={tab_item <- @tab_item} {assigns_to_attributes(tab_item)}>
          <%= render_slot(tab_item) %>
        </:item>
      </.tabs>

      <%= render_slot(assigns[:menu] || []) %>
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
