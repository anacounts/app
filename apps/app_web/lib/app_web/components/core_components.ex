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

  ## Avatar

  @doc """
  Generates an avatar.

  [INSERT LVATTRDOCS]

  ## Examples

      <.avatar src="https://avatars0.githubusercontent.com/u/1234?s=460&v=4" alt="GitHub avatar" />

  """

  attr :src, :string, required: true, doc: "The source of the image"
  attr :alt, :string, required: true, doc: "The alt text for the image"
  attr :size, :atom, default: :md, values: [:md, :lg], doc: "The size of the avatar"

  def avatar(assigns) do
    ~H"""
    <img class={["avatar", avatar_size_class(@size)]} src={@src} alt={@alt} />
    """
  end

  defp avatar_size_class(:md), do: "avatar--md"
  defp avatar_size_class(:lg), do: "avatar--lg"

  ## Button

  @doc """
  Buttons are used to trigger actions or navigate.

  Buttons are rendered as `<button>` elements by default. If any of the link attributes
  (`navigate`, `patch`, `href`) are present, the button will be rendered using the
  `link/1` component of Phoenix.

  ## Colors

  Buttons have three colors, `:cta`, `:feature`, and `:ghost`.

  CTA (short for Call to Action) buttons are used for the primary action in a view.
  They draw the user's attention and are used to guide the user to an significant step,
  whether it is to submit a form, create a new entry, close a popup, etc. There cannot
  be more than one CTA button on the screen at a time.

  Feature and Ghost buttons are used for secondary actions.
  """

  attr :color, :atom,
    required: true,
    values: [:cta, :feature, :ghost],
    doc: "The color of the button"

  attr :class, :any, default: nil, doc: "Extend component classes"

  attr :rest, :global,
    include: @link_attrs ++ ~w(form formaction formenctype formmethod formnovalidate formtarget)

  slot :inner_block

  def button(assigns) do
    ~H"""
    <.link_or_button class={["button", button_color_class(@color), @class]} {@rest}>
      <%= render_slot(@inner_block) %>
    </.link_or_button>
    """
  end

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
  Renders flash notices.

  ## Examples

      <.flash kind={:info} flash={@flash} />
      <.flash kind={:info} phx-mounted={show("#flash")}>Welcome Back!</.flash>
  """
  attr :id, :string, doc: "the optional id of flash container"
  attr :flash, :map, default: %{}, doc: "the map of flash messages to display"
  attr :title, :string, default: nil
  attr :kind, :atom, values: [:info, :error], doc: "used for styling and flash lookup"
  attr :rest, :global, doc: "the arbitrary HTML attributes to add to the flash container"

  slot :inner_block, doc: "the optional inner block that renders the flash message"

  def flash(assigns) do
    assigns = assign_new(assigns, :id, fn -> "flash-#{assigns.kind}" end)

    ~H"""
    <div
      :if={msg = render_slot(@inner_block) || Phoenix.Flash.get(@flash, @kind)}
      id={@id}
      phx-click={JS.push("lv:clear-flash", value: %{key: @kind}) |> hide("##{@id}")}
      role="alert"
      class={["flash", @kind == :info && "flash--info", @kind == :error && "flash--error"]}
      {@rest}
    >
      <p :if={@title} class="flash__title">
        <.icon :if={@kind == :info} name="info" class="flash__icon" />
        <.icon :if={@kind == :error} name="error" class="flash__icon" />
        <%= @title %>
      </p>
      <p class="flash__body"><%= msg %></p>
      <button type="button" class="group flash__close-button" aria-label={gettext("Close")}>
        <.icon name="close" class="flash__close-icon" />
      </button>
    </div>
    """
  end

  @doc """
  Shows the flash group with standard titles and content.

  ## Examples

      <.flash_group flash={@flash} />
  """
  attr :flash, :map, required: true, doc: "the map of flash messages"
  attr :id, :string, default: "flash-group", doc: "the optional id of flash container"

  def flash_group(assigns) do
    ~H"""
    <div id={@id}>
      <.flash kind={:info} title={gettext("Success!")} flash={@flash} />
      <.flash kind={:error} title={gettext("Error!")} flash={@flash} />
      <.flash
        id="client-error"
        kind={:error}
        title={gettext("We can't find the internet")}
        phx-disconnected={show(".phx-client-error #client-error")}
        phx-connected={hide("#client-error")}
        hidden
      >
        <%= gettext("Attempting to reconnect") %>
        <.icon name="autorenew" class="ml-1 h-4 w-4 animate-spin" />
      </.flash>

      <.flash
        id="server-error"
        kind={:error}
        title={gettext("Something went wrong!")}
        phx-disconnected={show(".phx-server-error #server-error")}
        phx-connected={hide("#server-error")}
        hidden
      >
        <%= gettext("Hang in there while we get back on track") %>
        <.icon name="autorenew" class="ml-1 h-4 w-4 animate-spin" />
      </.flash>
    </div>
    """
  end

  @doc """
  Generates a heading element.

  [INSERT LVATTRDOCS]

  ## Examples

      <.heading level={:section}>
        Section title
      </.heading>

  """

  attr :level, :atom, required: true, values: [:section], doc: "The level of the heading"
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

  defp heading_level_tag(:section), do: "h2"

  defp heading_level_class(:section), do: "heading--section"

  ## Icon

  @doc """
  Icons may be used in a variety of contexts to provide visual cues and enhance the user
  experience.

  See them used in other components, like "Button".

  ## Icon sets

  The icon component is currently works with two icon sets:
  - the `:heroicons` library, which should be the default choice as of now,
  - and custom icons found in `assets/icons/`, which are bundled into a
    single sprite. These icons are deprecated and should be replaced by
    `:heroicons` icons.
  """

  attr :name, :string, required: true, doc: "The name of the icon"
  attr :alt, :string, default: nil, doc: "The alt text of the icon"
  attr :class, :any, default: nil, doc: "Extra classes to add to the icon"
  attr :rest, :global

  # TODO deprecated, remove
  attr :size, :atom, default: nil, values: [nil, :md, :lg], doc: "The size of the icon"

  def icon(%{name: name} = assigns) when is_binary(name) do
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

  def icon(assigns) do
    ~H"""
    <.heroicon name={@name} aria-label={@alt} class={["icon icon--hero", @class]} {@rest} />
    """
  end

  # Copied from Github's heroicons_elixir issue #21.
  # https://github.com/mveytsman/heroicons_elixir/issues/21#issuecomment-1288551770
  attr :name, :atom, required: true
  attr :outline, :boolean, default: true
  attr :solid, :boolean, default: false
  attr :mini, :boolean, default: false

  attr :rest, :global,
    doc: "the arbitrary HTML attributes for the svg container",
    include: ~w(fill stroke stroke-width)

  def heroicon(assigns) do
    apply(Heroicons, assigns.name, [assigns])
  end

  # TODO deprecated, remove
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
  Generates a popup element.

  ## Example

      <.popup id="popup">
        <:title>Popup title</:title>

        <p>Popup body</p>
      </.popup>

  """

  attr :id, :string, required: true, doc: "The id of the popup"
  attr :class, :any, default: nil, doc: "Classes to apply to the popup dialog element"
  attr :rest, :global, include: ~w(open)

  slot :label, required: true
  slot :title, required: true
  slot :inner_block, required: true
  slot :footer

  def popup(assigns) do
    ~H"""
    <dialog id={@id} class={["popup", @class]} {@rest}>
      <header class="popup__header">
        <p class="label"><%= render_slot(@label) %></p>
        <h1 class="text-3xl font-bold"><%= render_slot(@title) %></h1>
        <.button color={:ghost} class="popup__dismiss" phx-click={hide_dialog("##{@id}")}>
          <.icon name="close" />
        </.button>
      </header>
      <div class="popup__body">
        <%= render_slot(@inner_block) %>
      </div>
      <footer class="popup__footer">
        <%= render_slot(@footer) %>
      </footer>
    </dialog>
    """
  end

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
  attr :summary_class, :any, default: nil, doc: "Extra classes to add to the tile summary"

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
    <details class={["tile", @class]} {@rest}>
      <summary class={["tile__summary", @summary_class]}>
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
    <.link class={["tile tile--clickable", @class]} navigate={@navigate} {@rest}>
      <div class={["tile__summary", @summary_class]}>
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
    values: ~w(checkbox color date datetime-local email file hidden money month number
               password range radio search select tel text textarea time toggle-group url week)

  attr :field, Phoenix.HTML.FormField,
    doc: "a form field struct retrieved from the form, for example: @form[:email]"

  attr :errors, :list, default: []
  attr :checked, :boolean, doc: "the checked flag for checkbox inputs"
  attr :prompt, :string, default: nil, doc: "the prompt for select inputs"

  attr :options, :list,
    doc:
      "the options to pass to Phoenix.HTML.Form.options_for_select/2, or for the toggle-group input"

  attr :multiple, :boolean, default: false, doc: "the multiple flag for select inputs"

  attr :label_class, :any, default: nil, doc: "Extra classes to add to the label"
  attr :rest, :global, include: ~w(autocomplete cols disabled form max maxlength min minlength
                                   pattern placeholder readonly required rows size step)

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
    <label class={@label_class} phx-feedback-for={@name}>
      <input type="hidden" name={@name} value="false" />
      <input type="checkbox" id={@id || @name} name={@name} value="true" checked={@checked} {@rest} />
      <%= @label %>
      <.error :for={msg <- @errors}><%= msg %></.error>
    </label>
    """
  end

  def input(%{type: "radio"} = assigns) do
    # Some attributes aren't handled or are handled improperly because they were
    # not needed in the original implementation. They can be added as needed.
    # e.g. `:checked` does not work

    # `:errors` are not displayed since they would be duplicated for each radio button

    ~H"""
    <label class={@label_class} phx-feedback-for={@name}>
      <input type="radio" name={@name} value={@value} {@rest} />
      <%= @label %>
    </label>
    """
  end

  def input(%{type: "select"} = assigns) do
    ~H"""
    <label class={@label_class} phx-feedback-for={@name}>
      <%= @label %>
      <select id={@id} name={@name} multiple={@multiple} {@rest}>
        <option :if={@prompt} value=""><%= @prompt %></option>
        <%= Phoenix.HTML.Form.options_for_select(@options, @value) %>
      </select>
      <.error :for={msg <- @errors}><%= msg %></.error>
    </label>
    """
  end

  def input(%{type: "textarea"} = assigns) do
    ~H"""
    <label class={@label_class} phx-feedback-for={@name}>
      <%= @label %>
      <textarea id={@id || @name} name={@name} {@rest}><%= Phoenix.HTML.Form.normalize_value("textarea", @value) %></textarea>
      <.error :for={msg <- @errors}><%= msg %></.error>
    </label>
    """
  end

  def input(%{type: "money"} = assigns) do
    assigns =
      assign_new(assigns, :normalized_value, fn ->
        # XXX When supporting other currencies, the rounding must be done based on the
        # currency's precision.
        if assigns.value, do: Decimal.round(assigns.value.amount, 2)
      end)

    ~H"""
    <div class="flex items-end gap-4">
      <label class={@label_class} phx-feedback-for={@name}>
        <%= @label %>
        <input
          type="number"
          name={@name}
          id={@id || @name}
          value={Phoenix.HTML.Form.normalize_value("number", @normalized_value)}
          step="0.01"
          {@rest}
        />
        <.error :for={msg <- @errors}><%= msg %></.error>
      </label>
      <label class={@label_class}>
        <select disabled>
          <%= Phoenix.HTML.Form.options_for_select(currencies_options(), "EUR") %>
        </select>
      </label>
    </div>
    """
  end

  def input(%{type: "toggle-group"} = assigns) do
    ~H"""
    <div class={@label_class} phx-feedback-for={@name}>
      <%= @label %>
      <div class="toggle-group">
        <label :for={option <- @options} class="toggle-group__label">
          <input
            type="radio"
            name={@name}
            id={option[:id]}
            value={option[:value]}
            checked={{:safe, option[:value]} == Phoenix.HTML.html_escape(@value)}
            class="toggle-group__input"
            {@rest}
          />
          <%= option[:key] %>
        </label>
      </div>
      <.error :for={msg <- @errors}><%= msg %></.error>
    </div>
    """
  end

  def input(assigns) do
    ~H"""
    <label class={@label_class} phx-feedback-for={@name}>
      <%= @label %>
      <input
        type={@type}
        name={@name}
        id={@id || @name}
        value={Phoenix.HTML.Form.normalize_value(@type, @value)}
        {@rest}
      />
      <.error :for={msg <- @errors}><%= msg %></.error>
    </label>
    """
  end

  defp currencies_options do
    [[key: "€", value: "EUR"]]
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

  ## JS Commands

  def show(js \\ %JS{}, selector) do
    JS.show(js,
      to: selector,
      transition:
        {"transition-all transform ease-out duration-300",
         "opacity-0 translate-y-4 sm:translate-y-0 sm:scale-95",
         "opacity-100 translate-y-0 sm:scale-100"}
    )
  end

  def hide(js \\ %JS{}, selector) do
    JS.hide(js,
      to: selector,
      time: 200,
      transition:
        {"transition-all transform ease-in duration-200",
         "opacity-100 translate-y-0 sm:scale-100",
         "opacity-0 translate-y-4 sm:translate-y-0 sm:scale-95"}
    )
  end

  def show_dialog(js \\ %JS{}, selector) do
    JS.dispatch(js, "app:open-dialog", to: selector)
  end

  def hide_dialog(js \\ %JS{}, selector) do
    JS.dispatch(js, "app:close-dialog", to: selector)
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
