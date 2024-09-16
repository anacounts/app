defmodule AppWeb.CoreComponents do
  @moduledoc """
  Provides core UI components.

  The components defined here are the base building blocks of the application.
  They define and represent the design system of the application.

  Related CSS can be found in `assets/css/components/*`.
  """
  use Phoenix.Component

  # TODO(v2,end) remove gettext from this file
  use AppWeb, :gettext

  alias Phoenix.LiveView.JS

  # Some components need to pass attributes down to a <.link> component. The attributes
  # of the <.link> component are sometimes out of scope of the `:global` type, but this
  # can be overriden using the `:include` option of `attr/3`.
  # e.g. `attr :rest, :global, include: @link_attrs`
  @link_attrs ~w(navigate patch href replace method csrf_token download hreflang referrerpolicy rel target type)

  # Attributes of the `<input>` HTML element
  @input_attrs ~w(name value checked)

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

  # prepend a class in `[:rest, :class]`
  defp prepend_class(assigns, class) do
    update(assigns, :rest, fn rest -> Map.update(rest, :class, class, &[class, &1]) end)
  end

  ## Alert

  @doc """
  An alert is a message that attracts the user's attention to important information.

  Alerts should be top-level components, placed directly within the body of the page.
  They should take the full width of the screen and should be placed at the beginning
  of the page so that they are visible to the user as soon as the page loads.
  """
  attr :kind, :atom, values: [:info, :warning, :error]

  attr :rest, :global

  slot :inner_block, required: true

  def alert(assigns) do
    assigns = prepend_class(assigns, ["alert", alert_kind_class(assigns.kind)])

    ~H"""
    <div {@rest}>
      <%= alert_icon(assigns) %>
      <%= render_slot(@inner_block) %>
    </div>
    """
  end

  defp alert_kind_class(:info), do: "alert--info"
  defp alert_kind_class(:warning), do: "alert--warning"
  defp alert_kind_class(:error), do: "alert--error"

  defp alert_icon(%{kind: :info} = assigns), do: ~H"<.icon name={:information_circle} />"
  defp alert_icon(%{kind: :warning} = assigns), do: ~H"<.icon name={:exclamation_triangle} />"
  defp alert_icon(%{kind: :error} = assigns), do: ~H"<.icon name={:exclamation_circle} />"

  @doc """
  Alert flashes display `alert/1` components based on flash messages.
  """
  attr :flash, :map, doc: "The @flash assign"
  attr :kind, :atom, values: [:info, :error]

  attr :rest, :global

  def alert_flash(assigns) do
    assigns =
      assign(assigns, :message, Phoenix.Flash.get(assigns.flash, assigns.kind))

    ~H|<.alert :if={@message} kind={@kind} {@rest}><%= @message %></.alert>|
  end

  ## Anchor

  @doc """
  An anchor is a stylized link that is used to navigate to a different page.
  """
  attr :rest, :global, include: @link_attrs

  slot :inner_block, required: true

  def anchor(assigns) do
    assigns = prepend_class(assigns, "anchor")

    ~H|<.link {@rest}><%= render_slot(@inner_block) %></.link>|
  end

  ## Accordion

  # TODO(v2,end) drop `accordion/1` component

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
  An avatar is a visual representation of a user or entity.

  Avatar must always be accompanied by an `alt` attribute to provide a meaningful
  description of the image for screen readers.
  """

  attr :src, :string, required: true
  attr :alt, :string, required: true
  # TODO(v2,end) remove `:md` and `:lg` values
  attr :size, :atom, default: :sm, values: [:sm, :hero, :md, :lg]

  attr :rest, :global

  def avatar(assigns) do
    assigns = prepend_class(assigns, ["avatar", avatar_size_class(assigns.size)])

    ~H"""
    <img src={@src} alt={@alt} {@rest} />
    """
  end

  defp avatar_size_class(:sm), do: "avatar--sm"
  defp avatar_size_class(:hero), do: "avatar--hero"
  defp avatar_size_class(deprecated) when deprecated in [:sm, :lg], do: nil

  ## breadcrumb

  @doc """
  Breadcrumbs are a navigation aid that helps users understand where they are in the
  application and allow them to navigate back to a higher level in the hierarchy.

  Breadcrumbs are placed at the top of the page. They should not contain more than
  two items. If there are more than two items, replace the excess by
  the `breadcrumb_ellipsis/1` component.

  This component should be used in conjunction with the `breadcrumb_home/1` and
  `breadcrumb_item/1` components.
  """
  attr :rest, :global

  slot :inner_block, required: true

  def breadcrumb(assigns) do
    assigns = prepend_class(assigns, "breadcrumb")

    ~H"""
    <nav {@rest}>
      <%= render_slot(@inner_block) %>
    </nav>
    """
  end

  @doc """
  The breadcrumb home item is a special breadcrumb item representing the home of the
  navigation hierarchy.

  It should be the first item in the breadcrumb list. Although it is not marked as
  required, the component should always contain any of a `href`, a `navigate`, or a
  `patch` attribute.

  This component should be used within the `breadcrumb/1` component.
  """
  attr :alt, :string, required: true

  attr :rest, :global, include: @link_attrs

  def breadcrumb_home(assigns) do
    ~H"""
    <.link {@rest}>
      <.icon name={:home} alt={@alt} />
    </.link>
    """
  end

  @doc """
  A breadcrumb item is an item representing a step in the navigation hierarchy in a
  breadcrumb component.

  The item component contains the chevron preceding it.

  If it is not the last item of the list, the component should always contain a
  `navigate` attribute linking to the corresponding page.

  This component should be used within the `breadcrumb/1` component.
  """
  attr :navigate, :string

  slot :inner_block, required: true

  def breadcrumb_item(%{navigate: _} = assigns) do
    ~H"""
    <.icon name={:chevron_right} />
    <.link class="breadcrumb__item">
      <%= render_slot(@inner_block) %>
    </.link>
    """
  end

  def breadcrumb_item(assigns) do
    ~H"""
    <.icon name={:chevron_right} />
    <span class="breadcrumb__item breadcrumb__item--active">
      <%= render_slot(@inner_block) %>
    </span>
    """
  end

  @doc """
  The breadcrumb ellipsis is a special item it used when there are too many items in a
  breadcrumb component.

  It is used as the second item of the list, right after the home item.

  This component should be used within the `breadcrumb/1` component.
  """
  def breadcrumb_ellipsis(assigns) do
    ~H"""
    <.icon name={:chevron_right} />
    <span class="breadcrumb__item breadcrumb__item--ellipsis">…</span>
    """
  end

  ## Button

  @doc """
  Buttons are used to trigger actions or navigate.

  Buttons are rendered as `<button>` elements by default. If the `:navigate` attribute
  is given, the button will be rendered using the `link/1` component of Phoenix.

  ## Kinds

  Buttons have three kinds, `:primary`, `:secondary`, and `:ghost`.

  Primary buttons are sometimes called "Call to action", and are used for the primary
  action in a view. They draw the user's attention and are used to guide the user to a
  significant step, whether it is to submit a form, create a new entry, close a popup,
  etc. There cannot be more than one CTA button on the screen at a time.

  Feature and Ghost buttons are used for secondary actions.
  """

  attr :kind, :atom,
    # TODO(v2,end) make `:kind` attribute required
    # required: true,
    default: :secondary,
    values: [:primary, :secondary, :ghost]

  attr :navigate, :string, doc: "A URL to navigate to when clicking the button"

  # TODO(v2,end) remove `:color` attribute
  attr :color, :atom, values: [:cta, :feature, :ghost]

  attr :rest, :global,
    include: @link_attrs ++ ~w(form formaction formenctype formmethod formnovalidate formtarget)

  slot :inner_block, required: true

  def button(%{navigate: _} = assigns) do
    assigns = prepend_button_classes(assigns)

    link(assigns)
  end

  def button(assigns) do
    assigns = prepend_button_classes(assigns)

    ~H"""
    <button {@rest}>
      <%= render_slot(@inner_block) %>
    </button>
    """
  end

  defp prepend_button_classes(assigns) do
    prepend_class(assigns, ["button", button_kind_class(assigns.kind)])
  end

  defp button_kind_class(:primary), do: "button--primary"
  defp button_kind_class(:secondary), do: "button--secondary"
  defp button_kind_class(:ghost), do: "button--ghost"

  @doc """
  Button groups are used to group buttons together.
  """
  attr :rest, :global

  slot :inner_block

  def button_group(assigns) do
    assigns = prepend_class(assigns, "button-group")

    ~H|<div {@rest}><%= render_slot(@inner_block) %></div>|
  end

  ## Card

  @doc """
  Cards are simple containers. They consist of white boxes with rounded corners,
  containing a title and a body. In most cases, the body is a simple short text,
  but more complex content can be added.
  """
  attr :color, :atom,
    values: [:secondary, :green, :red, :neutral],
    default: :secondary,
    doc: """
    The color of the card is used when displaying the balance of members, conveying the
    idea of positive, negative, and undefined balances.
    """

  attr :rest, :global

  slot :title, required: true
  slot :inner_block, required: true

  def card(assigns) do
    assigns = prepend_card_classes(assigns)

    ~H"""
    <div {@rest}>
      <div class="card__title">
        <%= render_slot(@title) %>
      </div>
      <div class="card__body">
        <%= render_slot(@inner_block) %>
      </div>
    </div>
    """
  end

  @doc """
  Card buttons are a specialized version of the card component that contains act as
  a button or link and only contain an icon and label.

  Unlike traditional cards, card buttons do not have a title slot since the title is
  the main content of the component.

  Card buttons cannot be used to display balance, so they cannot be green, red, or
  neutral. They can however be primary or secondary. The same usage rules as the button
  component apply.
  """
  attr :icon, :atom
  attr :color, :atom, values: [:primary, :secondary], default: :secondary

  attr :rest, :global

  slot :inner_block, required: true

  def card_button(assigns) do
    assigns = prepend_card_classes(assigns, "card--button")

    ~H"""
    <div {@rest}>
      <.icon name={@icon} />
      <%= render_slot(@inner_block) %>
    </div>
    """
  end

  defp prepend_card_classes(assigns, extra_classes \\ nil) do
    prepend_class(assigns, ["card", card_color_class(assigns.color), extra_classes])
  end

  defp card_color_class(:primary), do: "card--primary"
  defp card_color_class(:secondary), do: "card--secondary"
  defp card_color_class(:green), do: "card--green"
  defp card_color_class(:red), do: "card--red"
  defp card_color_class(:neutral), do: "card--neutral"

  ## Card grid

  @doc """
  Card grid are used to display a collection of cards in a grid layout.

  The grid contains two columns of equal width.
  """
  slot :inner_block, required: true

  def card_grid(assigns) do
    ~H"""
    <div class="card-grid">
      <%= render_slot(@inner_block) %>
    </div>
    """
  end

  ## Checkbox

  @doc """
  Checkboxes are used to let the user choose whether to activate an option when a form
  submission.

  When the effect of the checkbox is immediate, switches should be used instead.
  (NB, no switch component has been developed yet).

  For usage with Phoenix's forms, consider using the `input/1` component.
  """
  attr :rest, :global, include: @input_attrs

  def checkbox(assigns) do
    assigns = prepend_class(assigns, "checkbox")

    ~H"""
    <input type="checkbox" {@rest} />
    """
  end

  ## Divider

  @doc """
  Dividers are used to separate distinct sectionss of content.

  For example, they are used to separate the login form from
  the sign-up button in the login page, or to separate the
  items of a list (although it's implemented in a different way,
  the visual is the same).
  """

  attr :rest, :global

  def divider(assigns) do
    assigns = prepend_class(assigns, "divider")

    ~H"""
    <hr {@rest} />
    """
  end

  ## Dropdown

  # TODO(v2,end) drop `dropdown/1` component

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

  # TODO(v2,end) drop `fab_container/1` and `fab/1` components

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

  # TODO(v2,end) drop `flash/1` and `flash_group/1` components

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

  # TODO(v2,end) drop `heading/1` component

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
  """

  # TODO (v2,end) drop binary name support, set type to `:atom`
  attr :name, :any, required: true, doc: "The name of the icon"
  attr :alt, :string, default: nil, doc: "The alt text of the icon"
  attr :class, :any, default: nil, doc: "Extra classes to add to the icon"
  attr :rest, :global

  # TODO (v2,end) deprecated, remove
  attr :size, :atom, default: nil, values: [nil, :md, :lg], doc: "The size of the icon"

  # TODO (v2,end) drop binary name support
  def icon(%{name: name} = assigns) when is_binary(name), do: ~H""

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

  ## List

  @doc """
  Lists are used to display a collection of items in a vertical list.
  """
  attr :rest, :global

  slot :inner_block, required: true

  def list(assigns) do
    assigns = prepend_class(assigns, "list")

    ~H"""
    <ul {@rest}>
      <%= render_slot(@inner_block) %>
    </ul>
    """
  end

  @doc """
  List items are used within lists to display items.

  When using buttons within list item, consider using `list_item_link/1` instead.

  This component should be used within the `list/1` component.
  """
  attr :rest, :global

  slot :inner_block, required: true

  def list_item(assigns) do
    assigns = prepend_class(assigns, "list__item")

    ~H"""
    <li {@rest}>
      <%= render_slot(@inner_block) %>
    </li>
    """
  end

  @doc """
  List item links are variants of list items that are used to navigate.

  They should contain a ghost button placed at the end of the item, indicating the intent
  to navigate to a different page.

  This component should be used within the `list/1` component.
  """
  attr :rest, :global, include: @link_attrs

  slot :inner_block, required: true

  def list_item_link(assigns) do
    assigns = prepend_class(assigns, "list__item list__item--link")

    ~H"""
    <.link role="listitem" {@rest}>
      <%= render_slot(@inner_block) %>
    </.link>
    """
  end

  # TODO(v2,end) drop `popup/1` component

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

  ## Select

  @doc """
  Selects are form controls used to input data from a list of options.

  For usage with Phoenix's forms, consider using the `input/1` component.
  """

  attr :prompt, :string,
    default: nil,
    doc: "the prompt to display as the first option of the select"

  attr :value, :any, default: nil, doc: "the initially selected value"
  attr :options, :list, doc: "the options to pass to Phoenix.HTML.Form.options_for_select/2"

  attr :error, :boolean, default: false

  attr :container_class, :any, default: nil, doc: "Classes added to the input container"
  attr :rest, :global, include: @input_attrs

  def select(assigns) do
    assigns = prepend_class(assigns, "text-input__input text-input__input--select")

    ~H"""
    <div class={[
      "text-input",
      text_input_error_class(assigns.error),
      @container_class
    ]}>
      <select {@rest}>
        <option :if={@prompt} value=""><%= @prompt %></option>
        <%= Phoenix.HTML.Form.options_for_select(@options, @value) %>
      </select>
    </div>
    """
  end

  ## Tile

  @doc """
  Deprecated
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

  def deprecated_tile(%{collapse: true} = assigns) do
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

  def deprecated_tile(%{navigate: _} = assigns) do
    ~H"""
    <.link class={["tile tile--clickable", @class]} navigate={@navigate} {@rest}>
      <div class={["tile__summary", @summary_class]}>
        <%= render_slot(@inner_block) %>
      </div>
    </.link>
    """
  end

  ## Tabs

  # TODO(v2,end) drop `tabs/1` component

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

  ## Text input

  @doc """
  Text inputs are used to collect data from the user.

  The name `text_input` is used to differentiate from the `input/1` component,
  but the input can actually be used for multiple types of input, listed in the
  `:type` attribute.

  For usage with Phoenix's forms, consider using the `input/1` component.
  """

  attr :type, :string, default: "text", values: ~w(date email number password text)
  attr :error, :boolean, default: false

  attr :prefix, :atom, doc: "An icon to display before the input"
  attr :suffix, :atom, doc: "An icon to display after the input"

  attr :container_class, :any, default: nil, doc: "Classes added to the input container"
  attr :rest, :global, include: @input_attrs

  def text_input(assigns) do
    assigns = prepend_class(assigns, "text-input__input")

    ~H"""
    <div class={["text-input", text_input_error_class(assigns.error), @container_class]}>
      <%= text_input_prefix(assigns) %>
      <input type={@type} {@rest} />
      <%= text_input_suffix(assigns) %>
    </div>
    """
  end

  defp text_input_error_class(true), do: "text-input--error"
  defp text_input_error_class(false), do: nil

  defp text_input_prefix(%{prefix: _} = assigns) do
    ~H|<.icon class="text-input__addon" name={@prefix} />|
  end

  defp text_input_prefix(_assigns), do: nil

  defp text_input_suffix(%{suffix: _} = assigns) do
    ~H|<.icon class="text-input__addon" name={@suffix} />|
  end

  defp text_input_suffix(_assigns), do: nil

  ## Tile

  @doc """
  Tiles are interactive elements that are mostly used to navigate to different pages.
  """
  attr :color, :atom,
    values: [:primary, :secondary],
    default: :secondary

  attr :rest, :global

  slot :inner_block, required: true

  def tile(assigns) do
    assigns = prepend_class(assigns, ["tile", tile_color_class(assigns.color)])

    ~H"""
    <div {@rest}>
      <%= render_slot(@inner_block) %>
    </div>
    """
  end

  defp tile_color_class(:primary), do: "tile--primary"
  defp tile_color_class(:secondary), do: "tile--secondary"

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
               password range radio search select tel text time toggle-group url week)

  attr :field, Phoenix.HTML.FormField,
    doc: "a form field struct retrieved from the form, for example: @form[:email]"

  attr :helper, :string
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
    <div phx-feedback-for={@name} class="form-control-container">
      <input type="hidden" name={@name} value="false" />
      <.checkbox id={@id || @name} name={@name} value="true" checked={@checked} {@rest} />
      <label for={@id || @name}><%= @label %></label>
      <.error :for={msg <- @errors}><%= msg %></.error>
    </div>
    """
  end

  # TODO(v2,end) drop `radio` clause
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
    <div phx-feedback-for={@name}>
      <label for={@id || @name} class="label"><%= @label %></label>
      <.text_input
        type={@type}
        name={@name}
        id={@id || @name}
        value={Phoenix.HTML.Form.normalize_value(@type, @value)}
        {@rest}
      />
      <%= input_helper_or_errors(assigns) %>
    </div>
    """
  end

  defp currencies_options do
    [[key: "€", value: "EUR"]]
  end

  defp input_helper_or_errors(%{errors: [], helper: _} = assigns), do: ~H|<%= @helper %>|
  defp input_helper_or_errors(%{errors: []} = _assigns), do: nil
  defp input_helper_or_errors(assigns), do: ~H|<.error :for={msg <- @errors}><%= msg %></.error>|

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

  # TODO(v2,end) drop `show/2`, `hide/2`, `show_dialog/2` and `hide_dialog/2` helper functions

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
