defmodule AppWeb.ComponentHelpers do
  @moduledoc """
  A module defining components for live views.

  The components defined here are the base building blocks of the application.
  They define and represent the design system of the application.

  Related CSS can be found in `assets/css/components/*`.
  """

  import Phoenix.HTML.Tag, only: [content_tag: 3]
  import Phoenix.LiveView
  import Phoenix.LiveView.Helpers

  alias AppWeb.Endpoint
  alias AppWeb.Router.Helpers, as: Routes
  alias Phoenix.LiveView.JS

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
      <%= for item <- @item do %>
        <details
          class={["accordion__item", item[:class]]}
          {assigns_to_attributes(item, [:class, :title])}
        >
          <summary class="accordion__header">
            <strong class="accordion__title"><%= item.title %></strong>
            <.icon class="accordion__icon" name="chevron-down" />
          </summary>
          <%= render_slot(item) %>
        </details>
      <% end %>
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
  defp avatar_size_class("xl"), do: "avatar--xl"

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
  defp button_color_class("invisible"), do: "button--invisible"

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
          <.icon name="dots-vertical" alt={gettext("Contextual menu")} size="md" />
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
      <button class="dropdown__toggle" id={"#{@id}-toggle"} phx-click={toggle_dropdown(@id)}>
        <%= render_slot(@toggle) %>
      </button>
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
      <%= for item <- @item do %>
        <li>
          <%= render_slot(item) %>
        </li>
      <% end %>
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
    <%= live_redirect to: @to, class: "fab" do %>
      <%= render_slot(@inner_block) %>
    <% end %>
    """
  end

  def heading(assigns) do
    ~H"""
    <% {level_class, level_tag} = heading_level_class_and_tag(@level) %>
    <%= content_tag(level_tag, render_slot(@inner_block),
      class: ["heading", level_class, assigns[:class]]
    ) %>
    """
  end

  defp heading_level_class_and_tag("title"), do: {"heading--title", "h1"}
  defp heading_level_class_and_tag("section"), do: {"heading--section", "h3"}

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
      <%= if @alt do %>
        <title><%= @alt %></title>
      <% end %>
      <use href={icon_sprite_url(@name)} />
    </svg>
    """
  end

  defp icon_size_class(nil), do: nil
  defp icon_size_class("md"), do: "icon--md"

  defp icon_sprite_url(icon_name),
    do: Routes.static_path(Endpoint, "/assets/sprite.svg##{icon_name}")

  ## List

  def list(assigns) do
    ~H"""
    <ul class="list">
      <%= render_slot(@inner_block) %>
    </ul>
    """
  end

  def list_item(%{to: _to} = assigns) do
    link_opts =
      assigns
      |> Map.take([:to, :replace])
      |> Keyword.new()
      |> Keyword.put(:class, "list__item")

    assigns =
      assigns
      |> assign(:extra, assigns_to_attributes(assigns, [:class, :to, :replace]))
      |> assign(:link_opts, link_opts)

    ~H"""
    <li class={["contents", assigns[:class]]} {@extra}>
      <%= live_redirect @link_opts do %>
        <%= render_slot(@inner_block) %>
      <% end %>
    </li>
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

      <.toggle_nav>
        <:item
          icon="book"
          label="Books"
          to="/book"
          active
        />
        <:item
          icon="cog"
          label="Settings"
          to="/users/settings"
        />
      </.toggle_nav>

  """
  def toggle_nav(assigns) do
    ~H"""
    <nav class="toggle-nav">
      <menu class="toggle-nav__menu">
        <%= for item <- @item do %>
          <li class={["toggle-nav__item", toggle_nav_item_active_class(item.active)]}>
            <%= live_redirect to: item.to, replace: true, class: "toggle-nav__link" do %>
              <.icon name={item.icon} size="md" class="toggle-nav__item-icon" />
              <span><%= item.label %></span>
            <% end %>
          </li>
        <% end %>
      </menu>
    </nav>
    """
  end

  defp toggle_nav_item_active_class(true), do: "toggle-nav__item--active"
  defp toggle_nav_item_active_class(false), do: nil
end