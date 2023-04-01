defmodule AppWeb.CoreComponents do
  @moduledoc """
  Provides core UI components.

  The components defined here are the base building blocks of the application.
  They define and represent the design system of the application.

  Related CSS can be found in `assets/css/components/*`.
  """
  use Phoenix.Component
  use AppWeb, :verified_routes

  import AppWeb.Gettext

  alias Phoenix.LiveView.JS

  # Some components need to pass attributes down to a <.link> component. The attributes
  # of the <.link> component are sometimes out of scope of the `:global` type, but this
  # can be overriden using the `:include` option of `attr/3`.
  # e.g. `attr :rest, :global, include: @link_attrs`
  @link_attrs ~w(navigate patch href replace method csrf_token download hreflang referrerpolicy rel target type)

  # The <.link_or_button> component is used to conditionally render a link or a button
  # depending on the presence of the `navigate` attribute.

  defp link_or_button(%{navigate: _} = assigns), do: render_link(assigns)
  defp link_or_button(%{patch: _} = assigns), do: render_link(assigns)
  defp link_or_button(%{href: _} = assigns), do: render_link(assigns)

  defp link_or_button(assigns) do
    ~H"""
    <button {assigns_to_attributes(assigns)}>
      <%= render_slot(@inner_block) %>
    </button>
    """
  end

  defp render_link(assigns) do
    ~H"""
    <.link {assigns_to_attributes(assigns)}>
      <%= render_slot(@inner_block) %>
    </.link>
    """
  end

  ## Accordion

  @doc """
  Generates an accordion.

  ## Slots

  - item: The items of the accordion.
    - title: The title of the item

    - default slot: The content of the item

  ## Examples

      <.accordion title="Title">
        <:item title="Item 1" open>
          <p>Item 1 content</p>
        </:item>
        <:item title="Item 2">
          <p>Item 2 content</p>
        </:item>
      </.accordion>

  """
  def accordion(assigns) do
    assigns =
      assigns
      |> assign(:extra, assigns_to_attributes(assigns, [:class, :item]))

    ~H"""
    <div class={["accordion", assigns[:class]]} {@extra}>
      <details
        :for={item <- @item}
        class={["accordion__item", item[:class]]}
        {assigns_to_attributes(item, [:class, :title])}
      >
        <summary class="accordion__header">
          <strong class="accordion__title"><%= item.title %></strong>
          <.icon class="accordion__icon" name="expand-more" />
        </summary>
        <%= render_slot(item) %>
      </details>
    </div>
    """
  end

  ## Alert

  @doc """
  Generates an alert. Alerts are used to display temporary messages to the user.

  [INSERT LVATTRDOCS]

  ## Examples

      <.alert type="info">
        This is an info
      </.alert>

      <.alert type="error">
        This is an error
      </.alert>

  """

  attr :type, :string, required: true, values: ["info", "error"], doc: "The type of the alert"
  attr :class, :any, default: nil, doc: "Extra classes to add to the alert"
  attr :rest, :global

  slot :inner_block

  def alert(assigns) do
    ~H"""
    <div class={["alert", alert_type_class(@type), @class]} role="alert" {@rest}>
      <.icon name={alert_type_icon(@type)} />
      <%= render_slot(@inner_block) %>
    </div>
    """
  end

  defp alert_type_class("info"), do: "alert--info"
  defp alert_type_class("error"), do: "alert--error"

  defp alert_type_icon("info"), do: "info"
  defp alert_type_icon("error"), do: "error"

  ## Avatar

  @doc """
  Generates an avatar.

  [INSERT LVATTRDOCS]

  ## Examples

      <.avatar src="https://avatars0.githubusercontent.com/u/1234?s=460&v=4" alt="GitHub avatar" />

  """

  attr :src, :string, required: true, doc: "The source of the image"
  attr :alt, :string, required: true, doc: "The alt text for the image"
  attr :size, :atom, default: nil, values: [nil, :lg], doc: "The size of the avatar"

  def avatar(assigns) do
    ~H"""
    <img class={["avatar", avatar_size_class(@size)]} src={@src} alt={@alt} />
    """
  end

  defp avatar_size_class(nil), do: nil
  defp avatar_size_class(:lg), do: "avatar--lg"

  ## Button

  @doc """
  Generates a button.

  [INSERT LVATTRDOCS]

  ## Examples

      <.button color={:cta} type="submit">
        Submit
      </.button>

      <.button color={:feature}>
        Go to index
      </.button>

      <.button color={:ghost}>
        <.icon name="add" />
        Add
      </.button>

  """

  attr :color, :atom,
    required: true,
    values: [:cta, :feature, :ghost],
    doc: "The color of the button"

  attr :class, :any, default: nil, doc: "Extra classes to add to the button"
  attr :rest, :global, include: @link_attrs

  slot :inner_block

  def button(assigns) do
    ~H"""
    <.link_or_button class={["button", button_color_class(@color), @class]} {@rest}>
      <%= render_slot(@inner_block) %>
    </.link_or_button>
    """
  end

  defp button_color_class(nil), do: nil
  defp button_color_class(:cta), do: "button--cta"
  defp button_color_class(:feature), do: "button--feature"
  defp button_color_class(:ghost), do: "button--ghost"

  ## Dropdown

  @doc """
  Generates a dropdown.

  [INSERT LVATTRDOCS]

  ## Examples

      <.dropdown>
        <:toggle>
          <.icon name="more-vert" alt={gettext("Contextual menu")} size={:lg} />
        </:toggle>

        <.list_item>
          <.icon name="settings" />
          Settings
        </.list_item>
        <.list_item>
          <.icon name="out" />
          Disconnect
        </.list_item>
      </.dropdown>

  """

  attr :id, :string, required: true, doc: "The id of the dropdown"
  attr :class, :any, default: nil, doc: "Extra classes to add to the dropdown"

  slot :toggle, required: true, doc: "The content of the toggle button"
  slot :inner_block

  def dropdown(assigns) do
    ~H"""
    <div class={["dropdown", @class]} id={@id} phx-click-away={close_dropdown(@id)}>
      <.button
        color={:ghost}
        id={"#{@id}-toggle"}
        phx-click={toggle_dropdown(@id)}
        aria-expanded="false"
        aria-controls={"#{@id}-toggle"}
      >
        <%= render_slot(@toggle) %>
      </.button>
      <menu class="dropdown__menu list" id={"#{@id}-popover"} aria-labelledby={"#{@id}-toggle"}>
        <%= render_slot(@inner_block) %>
      </menu>
    </div>
    """
  end

  defp close_dropdown(id) do
    JS.set_attribute({"aria-expanded", "false"}, to: "#{id}-toggle")
    |> JS.hide(to: "##{id}-popover")
  end

  defp toggle_dropdown(id) do
    JS.set_attribute({"aria-expanded", "true"}, to: "#{id}-toggle")
    |> JS.toggle(to: "##{id}-popover")
  end

  ## FAB

  @doc """
  Generates a floating action button container.
  The container will place the buttons at the bottom right of the screen.

  [INSERT LVATTRDOCS]

  ## Examples

      <.fab_container>
        <:item>
          <.fab>
            <.icon name="settings" />
          </.fab>
        </:item>
      </.fab_container>

  """

  attr :class, :any, default: nil, doc: "Extra classes to add to the container"
  attr :rest, :global

  slot :item, required: true, doc: "The items of the floating action button container"

  def fab_container(assigns) do
    ~H"""
    <menu class={["fab-container", @class]} {@rest}>
      <li :for={item <- @item}>
        <%= render_slot(item) %>
      </li>
    </menu>
    """
  end

  @doc """
  Generates a floating action button.

  [INSERT LVATTRDOCS]

  ## Examples

      <.fab navigate="https://example.com">
        <.icon name="settings" />
      </.fab>

  """

  attr :rest, :global, include: @link_attrs

  slot :inner_block, required: true

  def fab(assigns) do
    ~H"""
    <.link class="fab" {@rest}>
      <%= render_slot(@inner_block) %>
    </.link>
    """
  end

  @doc """
  Generates a heading element.

  [INSERT LVATTRDOCS]

  ## Examples

      <.heading level={:title}>
        Title
      </.heading>

      <.heading level={:section}>
        Section title
      </.heading>

  """

  attr :level, :atom, required: true, values: [:title, :section], doc: "The level of the heading"
  attr :class, :any, default: nil, doc: "Extra classes to add to the heading"
  attr :rest, :global

  slot :inner_block, required: true

  def heading(assigns) do
    ~H"""
    <.dynamic_tag
      name={heading_level_tag(@level)}
      class={["heading", heading_level_class(@level), @class]}
      {@rest}
    >
      <%= render_slot(@inner_block) %>
    </.dynamic_tag>
    """
  end

  defp heading_level_tag(:title), do: "h1"
  defp heading_level_tag(:section), do: "h2"

  defp heading_level_class(:title), do: "heading--title"
  defp heading_level_class(:section), do: "heading--section"

  ## Icon

  @doc """
  Generates an icon.

  [INSERT LVATTRDOCS]

  ## Examples

      <.icon name="home" />

  """

  attr :name, :string, required: true, doc: "The name of the icon"
  attr :alt, :string, default: nil, doc: "The alt text of the icon"
  attr :size, :atom, default: nil, values: [nil, :md, :lg], doc: "The size of the icon"
  attr :class, :any, default: nil, doc: "Extra classes to add to the icon"
  attr :rest, :global

  def icon(assigns) do
    ~H"""
    <svg
      class={["icon", icon_size_class(@size), @class]}
      fill="currentColor"
      role="img"
      aria-hidden={"#{is_nil(@alt)}"}
      {@rest}
    >
      <title :if={@alt}><%= @alt %></title>
      <use href={icon_sprite_url(@name)} />
    </svg>
    """
  end

  defp icon_size_class(nil), do: nil
  defp icon_size_class(:md), do: "icon--md"
  defp icon_size_class(:lg), do: "icon--lg"

  defp icon_sprite_url(icon_name),
    do: ~p"/assets/sprite.svg##{icon_name}"

  ## List

  attr :rest, :global

  slot :inner_block

  def list(assigns) do
    ~H"""
    <ul class="list" {@rest}>
      <%= render_slot(@inner_block) %>
    </ul>
    """
  end

  def list_item(assigns) do
    assigns =
      assigns
      |> assign(:extra, assigns_to_attributes(assigns, [:class]))

    ~H"""
    <li class={["list__item", assigns[:class]]} {@extra}>
      <%= render_slot(@inner_block) %>
    </li>
    """
  end

  def list_item_link(assigns) do
    assigns =
      assigns
      |> assign(:extra, assigns_to_attributes(assigns, [:class]))

    ~H"""
    <li class="contents">
      <.link class={["list__item", assigns[:class]]} {@extra}>
        <%= render_slot(@inner_block) %>
      </.link>
    </li>
    """
  end

  @doc """
  Generates a modal element.

  ## Attributes

  - id (required): The id of the modal
  - size: The size of the modal. Defaults to "md"
  - open: Whether the modal is open by default or not. Defaults to false

  ## Slots

  - header: The header of the modal
  - inner_block: The body of the modal
  - footer: The footer of the modal

  ## Example

      <.modal id="modal">
        <:header>
          <.heading level={:title}>Modal title</.heading>
        </:header>

        <p>Modal body</p>

        <:footer>
          <.button color={:ghost}>Cancel</.button>
          <.button color="primary">Save</.button>
        </:footer>
      </.modal>

  """

  attr :id, :string, required: true, doc: "The id of the modal"
  attr :size, :atom, default: nil, values: [nil, :xl], doc: "The size of the modal"
  attr :dismiss, :boolean, default: true, doc: "Whether the modal contain a dismiss button"
  attr :open, :boolean, default: false, doc: "Whether the modal is open by default or not"

  slot :header
  slot :inner_block
  slot :footer

  def modal(assigns) do
    ~H"""
    <.focus_wrap id={@id} class={["modal", modal_size_class(@size), modal_open_class(@open)]}>
      <section class="modal__dialog" role="dialog">
        <header :if={@header || @dismiss} class="modal__header">
          <%= render_slot(@header) %>
          <.button
            :if={@dismiss}
            color={:ghost}
            class="modal__dismiss"
            phx-click={JS.remove_class("modal--open", to: "##{@id}")}
            aria-label={gettext("Close")}
          >
            <.icon name="close" />
          </.button>
        </header>
        <div class="modal__body">
          <%= render_slot(@inner_block) %>
        </div>
        <footer class="modal__footer">
          <%= render_slot(@footer) %>
        </footer>
      </section>
    </.focus_wrap>
    """
  end

  defp modal_size_class(nil), do: "modal--md"
  defp modal_size_class(:xl), do: "modal--xl"

  defp modal_open_class(true), do: "modal--open"
  defp modal_open_class(false), do: nil

  ## Tile

  @doc """
  A card is a flexible and extensible content container.

  ## When to use

  Cards can be used as navigation links, so that when the user clicks on them, they are
  taken to a new page. To enable this behavior, the `<.tile>` must receive a `navigate`
  attribute with the URL to navigate to.

  They can also be collapsible, so that when the user clicks on them, they are expanded
  to show more content. To enable this behavior, the `<.tile>` must receive a `collapse`
  attribute.

  These two behaviors are mutually exclusive. Links do not support the `header` and
  `button` slots.

  [INSERT LVATTRDOCS]

  ## Examples

      <.tile navigate="/book/1">
        My book name
      </.tile>

      <.tile collapse>
        <:header>
          Some content summarized
        </:header>

        The description of the content

        <:button>
          Edit
        </:button>
        <:button class="text-error">
          Delete
        </:button>
      </.tile>

  """

  attr :collapse, :boolean,
    default: false,
    doc: """
    Whether to collapse the tile.
    Incompatible with `:navigate` and `:clickable`
    """

  attr :navigate, :string,
    doc: """
    The URL to navigate to when clicking the tile.
    Incompatible with `:collapse`.
    """

  attr :class, :any, default: nil, doc: "Extra classes to add to the tile"

  attr :rest, :global

  slot :inner_block

  slot :description, doc: "When using collapsible tiles, the extended content of the tile"

  slot :button, doc: "The button appearing in the footer of the tile" do
    # XXX should be removed, circumvent a weird behaviour in LiveView
    # https://github.com/phoenixframework/phoenix_live_view/issues/2265
    attr :navigate, :string
    attr :class, :any
    attr :"data-confirm", :string
    attr :"phx-click", :string
    attr :"phx-value-id", :string
  end

  def tile(%{collapse: true} = assigns) do
    ~H"""
    <details class="tile" {@rest}>
      <summary class={["tile__summary", @class]}>
        <%= render_slot(@inner_block) %>
        <.icon class="tile__collapse-icon" name="expand-more" />
      </summary>
      <div class="tile__description">
        <%= render_slot(@description) %>
      </div>
      <div :if={not Enum.empty?(@button)} class="tile__footer">
        <.link_or_button
          :for={button <- @button}
          class={["tile__button", button[:class]]}
          {assigns_to_attributes(button, [:class])}
        >
          <%= render_slot(button) %>
        </.link_or_button>
      </div>
    </details>
    """
  end

  def tile(%{navigate: _} = assigns) do
    ~H"""
    <.link class="tile tile--clickable" navigate={@navigate} {@rest}>
      <div class={["tile__summary", @class]}>
        <%= render_slot(@inner_block) %>
      </div>
    </.link>
    """
  end

  ## Tabs

  @doc """
  Generates a tab menu.

  [INSERT LVATTRDOCS]

  ## Examples

      <.tabs>
        <:item to="/book" active>
          <.icon name="book" size={:md} />
          Books
        </:item>
        <:item to="/users/settings">
          <.icon name="settings" size={:md} />
          Settings
        </:item>
      </.tabs>

  """

  slot :item, required: true, doc: "The items of the tabs" do
    attr :navigate, :string, required: true
    attr :active, :boolean
  end

  def tabs(assigns) do
    ~H"""
    <menu class="tabs" role="navigation">
      <li :for={item <- @item} class="tabs__item">
        <.link
          navigate={item.navigate}
          replace
          class={["tabs__link", tabs_link_active_class(item[:active])]}
          aria-current={if item[:active], do: "page"}
        >
          <%= render_slot(item) %>
        </.link>
      </li>
    </menu>
    """
  end

  defp tabs_link_active_class(true), do: "tabs__link--active"
  defp tabs_link_active_class(_active?), do: nil

  @doc """
  Renders an input with label and error messages.

  A `%Phoenix.HTML.Form{}` and field name may be passed to the input
  to build input names and error messages, or all the attributes and
  errors may be passed explicitly.

  ## Examples

      <.input field={@form[:email]} type="email" />
      <.input name="my-input" errors={["oh no!"]} />
  """
  attr :id, :any, default: nil
  attr :name, :any
  attr :label, :string, default: nil
  attr :value, :any

  attr :type, :string,
    default: "text",
    values: ~w(checkbox color date datetime-local email file hidden month number password
               range radio search select tel text textarea time url week)

  attr :field, Phoenix.HTML.FormField,
    doc: "a form field struct retrieved from the form, for example: @form[:email]"

  attr :errors, :list, default: []
  attr :checked, :boolean, doc: "the checked flag for checkbox inputs"
  attr :prompt, :string, default: nil, doc: "the prompt for select inputs"
  attr :options, :list, doc: "the options to pass to Phoenix.HTML.Form.options_for_select/2"
  attr :multiple, :boolean, default: false, doc: "the multiple flag for select inputs"
  attr :rest, :global, include: ~w(autocomplete cols disabled form max maxlength min minlength
                                   pattern placeholder readonly required rows size step)
  slot :inner_block

  def input(%{field: %Phoenix.HTML.FormField{} = field} = assigns) do
    assigns
    |> assign(field: nil, id: assigns.id || field.id)
    |> assign(:errors, Enum.map(field.errors, &translate_error(&1)))
    |> assign_new(:name, fn -> if assigns.multiple, do: field.name <> "[]", else: field.name end)
    |> assign_new(:value, fn -> field.value end)
    |> input()
  end

  def input(%{type: "checkbox", value: value} = assigns) do
    assigns =
      assign_new(assigns, :checked, fn -> Phoenix.HTML.Form.normalize_value("checkbox", value) end)

    ~H"""
    <label phx-feedback-for={@name}>
      <input type="hidden" name={@name} value="false" />
      <input type="checkbox" id={@id || @name} name={@name} value="true" checked={@checked} {@rest} />
      <%= @label %>
      <.error :for={msg <- @errors}><%= msg %></.error>
    </label>
    """
  end

  def input(%{type: "select"} = assigns) do
    ~H"""
    <.label phx-feedback-for={@name}>
      <%= @label %>
      <select id={@id} name={@name} multiple={@multiple} {@rest}>
        <option :if={@prompt} value=""><%= @prompt %></option>
        <%= Phoenix.HTML.Form.options_for_select(@options, @value) %>
      </select>
      <.error :for={msg <- @errors}><%= msg %></.error>
    </.label>
    """
  end

  def input(%{type: "textarea"} = assigns) do
    ~H"""
    <.label phx-feedback-for={@name}>
      <%= @label %>
      <textarea id={@id || @name} name={@name} {@rest}><%= Phoenix.HTML.Form.normalize_value("textarea", @value) %></textarea>
      <.error :for={msg <- @errors}><%= msg %></.error>
    </.label>
    """
  end

  def input(assigns) do
    ~H"""
    <.label phx-feedback-for={@name}>
      <%= @label %>
      <input
        type={@type}
        name={@name}
        id={@id || @name}
        value={Phoenix.HTML.Form.normalize_value(@type, @value)}
        {@rest}
      />
      <.error :for={msg <- @errors}><%= msg %></.error>
    </.label>
    """
  end

  @doc """
  Renders a label.
  """
  attr :for, :string, default: nil
  attr :rest, :global
  slot :inner_block, required: true

  def label(assigns) do
    ~H"""
    <label for={@for} {@rest}>
      <%= render_slot(@inner_block) %>
    </label>
    """
  end

  @doc """
  Generates a generic error message.
  """
  slot :inner_block, required: true

  def error(assigns) do
    ~H"""
    <p class="phx-no-feedback:hidden text-error">
      <%= render_slot(@inner_block) %>
    </p>
    """
  end

  @doc """
  Translates an error message using gettext.
  """
  def translate_error({msg, opts}) do
    # When using gettext, we typically pass the strings we want
    # to translate as a static argument:
    #
    #     # Translate "is invalid" in the "errors" domain
    #     dgettext("errors", "is invalid")
    #
    #     # Translate the number of files with plural rules
    #     dngettext("errors", "1 file", "%{count} files", count)
    #
    # Because the error messages we show in our forms and APIs
    # are defined inside Ecto, we need to translate them dynamically.
    # This requires us to call the Gettext module passing our gettext
    # backend as first argument.
    #
    # Note we use the "errors" domain, which means translations
    # should be written to the errors.po file. The :count option is
    # set by Ecto and indicates we should also apply plural rules.
    if count = opts[:count] do
      Gettext.dngettext(AppWeb.Gettext, "errors", msg, msg, count, opts)
    else
      Gettext.dgettext(AppWeb.Gettext, "errors", msg, opts)
    end
  end

  @doc """
  Translates the errors for a field from a keyword list of errors.
  """
  def translate_errors(errors, field) when is_list(errors) do
    for {^field, {msg, opts}} <- errors, do: translate_error({msg, opts})
  end
end
