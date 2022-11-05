defmodule AppWeb.ComponentHelpers do
  @moduledoc """
  A module defining components for live views.

  The components defined here are the base building blocks of the application.
  They define and represent the design system of the application.

  Related CSS can be found in `assets/css/components/*`.
  """

  use Phoenix.Component

  import AppWeb.Gettext

  alias AppWeb.Endpoint
  alias AppWeb.Router.Helpers, as: Routes
  alias Phoenix.LiveView.JS

  # The <.link_or_button> component is used to conditionally render a link or a button
  # depending on the presence of the `navigate` attribute.

  defp link_or_button(%{navigate: _} = assigns) do
    ~H"""
    <.link {assigns_to_attributes(assigns)}>
      <%= render_slot(@inner_block) %>
    </.link>
    """
  end

  defp link_or_button(assigns) do
    ~H"""
    <button {assigns_to_attributes(assigns)}>
      <%= render_slot(@inner_block) %>
    </button>
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
          <.icon class="accordion__icon" name="chevron-down" />
        </summary>
        <%= render_slot(item) %>
      </details>
    </div>
    """
  end

  ## Alert

  @doc """
  Generates an alert. Alerts are used to display temporary messages to the user.

  ## Attributes

  - type: The type of the alert

  ## Slots

  - default: The content of the alert
             Note that an icon is automatically added to the alert.

  ## Examples

      <.alert type="info">
        This is an info
      </.alert>

  """
  def alert(assigns) do
    assigns =
      assigns
      |> assign(:extra, assigns_to_attributes(assigns, [:class, :type]))

    ~H"""
    <% {type_class, type_icon} = alert_type_class_and_icon(@type) %>
    <div class={["alert", type_class, assigns[:class]]} role="alert" {@extra}>
      <.icon name={type_icon} />
      <%= render_slot(@inner_block) %>
    </div>
    """
  end

  defp alert_type_class_and_icon("info"), do: {"alert--info", "information"}
  defp alert_type_class_and_icon("error"), do: {"alert--error", "alert-circle"}

  ## Avatar

  @doc """
  Generates an avatar.

  ## Attributes

  - src (required): The image URL.
  - alt: The alt text for the image.

  ## Examples

      <.avatar src="https://avatars0.githubusercontent.com/u/1234?s=460&v=4" alt="GitHub avatar" />

  """
  def avatar(assigns) do
    ~H"""
    <img class={["avatar", avatar_size_class(assigns[:size])]} src={@src} alt={assigns[:alt]} />
    """
  end

  defp avatar_size_class(nil), do: nil
  defp avatar_size_class(:lg), do: "avatar--lg"

  ## Button

  def button(assigns) do
    assigns =
      assigns
      |> assign(:extra, assigns_to_attributes(assigns, [:class, :color]))

    ~H"""
    <button class={["button", button_color_class(@color), assigns[:class]]} {@extra}>
      <%= render_slot(@inner_block) %>
    </button>
    """
  end

  defp button_color_class(nil), do: nil
  defp button_color_class("cta"), do: "button--cta"
  defp button_color_class("feature"), do: "button--feature"
  defp button_color_class("ghost"), do: "button--ghost"

  ## Dropdown

  @doc """
  Generates a dropdown.

  ## Attributes

  - id (required): The id of the dropdown

  ## Slots

  - toggle (required): The content of the toggle button
  - default: The content of the menu

  ## Examples

      <.dropdown>
        <:toggle>
          <.icon name="dots-vertical" alt={gettext("Contextual menu")} size={:lg} />
        </:toggle>

        <.list_item>
          <.icon name="cog" />
          Settings
        </.list_item>
        <.list_item>
          <.icon name="out" />
          Disconnect
        </.list_item>
      </.dropdown>

  """
  def dropdown(assigns) do
    ~H"""
    <div
      class={["dropdown", assigns[:class]]}
      aria-expanded="false"
      id={@id}
      phx-click-away={close_dropdown(@id)}
    >
      <.button color="ghost" id={"#{@id}-toggle"} phx-click={toggle_dropdown(@id)}>
        <%= render_slot(@toggle) %>
      </.button>
      <menu class="dropdown__menu list" id={"#{@id}-popover"} aria-labelledby={"#{@id}-toggle"}>
        <%= render_slot(@inner_block) %>
      </menu>
    </div>
    """
  end

  defp close_dropdown(id) do
    JS.set_attribute({"aria-expanded", "false"}, to: id)
    |> JS.hide(to: "##{id}-popover")
  end

  defp toggle_dropdown(id) do
    JS.set_attribute({"aria-expanded", "true"}, to: id)
    |> JS.toggle(to: "##{id}-popover")
  end

  ## FAB

  @doc """
  Generates a floating action button container.
  The container will place the buttons at the bottom right of the screen.

  ## Attributes

  All attributes are passed to the root `<menu>` element.

  ## Slots

  - item: The items of the floating action button container

  ## Examples

      <.fab_container>
        <:item>
          <.fab>
            <.icon name="cog" />
          </.fab>
        </:item>
      </.fab_container>

  """
  def fab_container(assigns) do
    assigns =
      assigns
      |> assign(:extra, assigns_to_attributes(assigns, [:class, :item]))

    ~H"""
    <menu class={["fab-container", assigns[:class]]} {@extra}>
      <li :for={item <- @item}>
        <%= render_slot(item) %>
      </li>
    </menu>
    """
  end

  @doc """
  Generates a floating action button.
  Should usually be used inside a `<.fab_container>` element.

  ## Attributes

  - to (required): The URL to which the button will link.

  ## Slots

  - default: The content of the floating action button.

  ## Examples

      <.fab to="https://example.com">
        <.icon name="cog" />
      </.fab>

  """
  def fab(assigns) do
    ~H"""
    <.link navigate={@to} class="fab">
      <%= render_slot(@inner_block) %>
    </.link>
    """
  end

  def heading(assigns) do
    ~H"""
    <.dynamic_tag
      name={heading_level_tag(@level)}
      class={["heading", heading_level_class(@level), assigns[:class]]}
    >
      <%= render_slot(@inner_block) %>
    </.dynamic_tag>
    """
  end

  defp heading_level_tag("title"), do: "h1"
  defp heading_level_tag("section"), do: "h3"

  defp heading_level_class("title"), do: "heading--title"
  defp heading_level_class("section"), do: "heading--section"

  ## Icon

  @doc """
  Generates an icon.

  ## Attributes

  - name (required): The name of the icon
  - alt: The alt text of the icon
  - size: The size of the icon. Defaults to "base"

  ## Examples

      <.icon name="home" />

  """
  def icon(assigns) do
    assigns =
      assigns
      |> assign(:extra, assigns_to_attributes(assigns, [:name, :alt, :class]))
      |> assign_new(:alt, fn -> nil end)

    ~H"""
    <svg
      class={["icon", icon_size_class(assigns[:size]), assigns[:class]]}
      fill="currentColor"
      role="img"
      aria-hidden={is_nil(@alt)}
      {@extra}
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
    do: Routes.static_path(Endpoint, "/assets/sprite.svg##{icon_name}")

  ## List

  attr :hoverable, :boolean, default: false, doc: "Whether the items are hoverable"
  attr :rest, :global

  slot(:inner_block)

  def list(assigns) do
    ~H"""
    <ul class={["list", list_hoverable_class(@hoverable)]} {@rest}>
      <%= render_slot(@inner_block) %>
    </ul>
    """
  end

  defp list_hoverable_class(true), do: "list--hoverable"
  defp list_hoverable_class(false), do: nil

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
          <.heading level="title">Modal title</.heading>
        </:header>

        <p>Modal body</p>

        <:footer>
          <.button color="ghost">Cancel</.button>
          <.button color="primary">Save</.button>
        </:footer>
      </.modal>

  """
  def modal(assigns) do
    ~H"""
    <.focus_wrap
      id={@id}
      class={["modal", modal_size_class(assigns[:size]), modal_open_class(assigns[:open])]}
    >
      <section class="modal__dialog" role="dialog">
        <header :if={assigns[:header] || assigns[:dismiss]} class="modal__header">
          <%= render_slot(@header) %>
          <.button
            :if={assigns[:dismiss] != false}
            color="ghost"
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

  defp modal_open_class(nil), do: nil
  defp modal_open_class(true), do: "modal--open"

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

  attr :size, :atom,
    default: :md,
    values: [:sm, :md],
    doc: "The size of the tile. Defaults to `:md`"

  attr :class, :any, default: nil, doc: "Extra classes to add to the tile"

  attr :rest, :global

  slot(:inner_block)

  slot(:description, doc: "When using collapsible tiles, the extended content of the tile")

  slot :button, doc: "The button appearing in the footer of the tile" do
    # XXX should be removed, circumvent a weird behaviour in LiveView
    # https://github.com/phoenixframework/phoenix_live_view/issues/2265
    attr :navigate, :string
    attr :class, :string
    attr :"data-confirm", :string
    attr :"phx-click", :string
    attr :"phx-value-id", :string
  end

  def tile(%{collapse: true} = assigns) do
    ~H"""
    <details class={["tile", tile_size_class(@size)]} {@rest}>
      <summary class={["tile__summary", @class]}>
        <%= render_slot(@inner_block) %>
        <.icon class="tile__collapse-icon" name="chevron-down" />
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
    <.link class={["tile tile--clickable", tile_size_class(@size)]} navigate={@navigate} {@rest}>
      <div class={["tile__summary", @class]}>
        <%= render_slot(@inner_block) %>
      </div>
    </.link>
    """
  end

  defp tile_size_class(:sm), do: "tile--sm"
  defp tile_size_class(:md), do: "tile--md"

  ## Toggle navigation

  @doc """
  Generates a toggle navigation menu.

  ## Slots

  - :item - The items of the toggle navigation
    - :icon - The icon to use
    - :label - The label to use
    - :to - The path to link to
    - :active - Whether the item is active or not

  ## Examples

      <.tabs>
        <:item to="/book" active>
          <.icon name="book" size={:md} />
          Books
        </:item>
        <:item to="/users/settings">
          <.icon name="cog" size={:md} />
          Settings
        </:item>
      </.tabs>

  """
  def tabs(assigns) do
    ~H"""
    <menu class={["tabs", assigns[:class]]} role="navigation">
      <li :for={item <- @item} class="tabs__item">
        <.link
          navigate={item.to}
          replace
          class={["tabs__link", tabs_link_active_class(item.active)]}
          aria-current={if item.active, do: "page"}
        >
          <%= render_slot(item) %>
        </.link>
      </li>
    </menu>
    """
  end

  defp tabs_link_active_class(active?) do
    if active?, do: "tabs__link--active"
  end
end
