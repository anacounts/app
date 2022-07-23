defmodule AppWeb.LiveHelpers do
  @moduledoc """
  Helper components for live views.
  Includes many common components commonly used throughout the app.
  """

  import Phoenix.LiveView
  import Phoenix.LiveView.Helpers

  import AppWeb.Gettext

  alias AppWeb.Endpoint
  alias AppWeb.Router.Helpers, as: Routes
  alias Phoenix.LiveView.JS

  ## Accordion

  @doc """
  Generates an accordion.

  ## Slots

  - default: The content of the accordion.

  ## Examples

      <.accordion title="Title">
        <.accordion_item title="Item 1" open>
          <p>Item 1 content</p>
        </.accordion_item>
        <.accordion_item title="Item 2" open>
          <p>Item 2 content</p>
        </.accordion_item>
      </.accordion>

  """
  def accordion(assigns) do
    ~H"""
    <div class="accordion">
      <%= render_slot(@inner_block) %>
    </div>
    """
  end

  @doc """
  Generates an accordion item.

  ## Attributes

  - title (required): The title of the accordion item.

  Other attributes are passed to the `<details>` element.

  ## Slots

  - default: The content of the accordion item.

  ## Examples

      <.accordion_item title="Item 1" open>
        <p>Item 1 content</p>
      </.accordion_item>

  """
  def accordion_item(assigns) do
    assigns =
      assigns
      |> assign(:extra, assigns_to_attributes(assigns, [:title]))

    ~H"""
    <details class="accordion__item" {@extra}>
      <summary class="accordion__header">
        <strong class="accordion__title"><%= @title %></strong>
        <% # Remove icon, make it pure CSS %>
        <.icon name="chevron-down" />
      </summary>
      <%= render_slot(@inner_block) %>
    </details>
    """
  end

  ## App header

  @doc """
  Generates the base header.

  ## Options

  - :back_to - The path to link to for the back button.
    Defaults to nil and does not display the back button.

  ## Slots

  - :menu - The menu to use
  - :menu_toggle - The menu toggle to use
  - default - The content of the page

  ## Examples

      <.app_header back_to="#">
        Anacounts

        <:menu>
          <.menu_item to="/users/settings">
            <.icon icon="cog" />
            Settings
          </.menu_item>
          <.menu_item to="/users/log_out" method="delete">
            <.icon icon="out" />
            Disconnect
          </.menu_item>
        </:menu>
      </.app_header>

  """
  def app_header(assigns) do
    assigns =
      assigns
      |> assign_new(:back_to, fn -> nil end)
      |> assign_new(:menu, fn -> nil end)
      |> assign_new(:menu_toggle, fn -> nil end)

    ~H"""
    <header class="app-header">
      <%= if @back_to do %>
        <%= live_redirect to: @back_to, class: "button button--color-invisible" do %>
          <.icon name="arrow-left" alt={gettext("Go back")} class="app-header__icon" />
        <% end %>
      <% end %>
      <h1 class="app-header__title"><%= render_slot(@inner_block) %></h1>
      <%= if @menu do %>
        <.dropdown id="contextual-menu">
          <:toggle>
            <%= if @menu_toggle do %>
              <%= render_slot(@menu_toggle) %>
            <% else %>
              <.icon
                name="dots-vertical"
                alt={gettext("Contextual menu")}
                size="md"
                class="app-header__icon"
              />
            <% end %>
          </:toggle>
          <%= render_slot(@menu) %>
        </.dropdown>
      <% end %>
    </header>
    """
  end

  ## Bottom navigation

  @doc """
  Generates a bottom nav.

  ## Examples

      <.bottom_nav>
        <.bottom_nav_item
          icon="book"
          label="Books"
          to="/book"
          active
        />
        <.bottom_nav_item
          icon="cog"
          label="Settings"
          to="/users/settings"
        />
      </.bottom_nav>

  """
  def bottom_nav(assigns) do
    ~H"""
    <nav class="bottom-nav">
      <menu class="bottom-nav__menu">
        <%= render_slot(@inner_block) %>
      </menu>
    </nav>
    """
  end

  @doc """
  Generates a button for the bottom nav.

  ## Attributes

  - icon (required): The name of the icon to use
  - label (required): The label to use for the button
  - to (required): The path to link to
  - active: Whether the button should be active or not. Defaults to false.
  - method: The HTTP method to use for the link. Defaults to :get

  ## Examples

      <.bottom_nav_item icon="books" label="Books" to="/books" method="delete" />

  """
  def bottom_nav_item(assigns) do
    assigns =
      assigns
      |> assign_new(:active, fn -> false end)
      |> assign_new(:method, fn -> :get end)

    ~H"""
    <li class={"bottom-nav__item #{bottom_nav_item_active_class(@active)}"}>
      <%= live_redirect to: @to, replace: true, method: @method, class: "bottom-nav__link" do %>
        <.icon name={@icon} class="bottom-nav__item-icon" />
        <span><%= @label %></span>
      <% end %>
    </li>
    """
  end

  defp bottom_nav_item_active_class(true), do: "bottom-nav__item--active"
  defp bottom_nav_item_active_class(false), do: ""

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
          <.icon name="dots-vertical" alt={gettext("Contextual menu")} class="app-header__icon" />
        </:toggle>
        <ul class="dropdown__menu">
          <li class="dropdown__item">
            <.icon name="cog" />
            Settings
          </li>
          <li class="dropdown__item">
            <.icon name="out" />
            Disconnect
          </li>
        </ul>
      </.dropdown>

  """
  def dropdown(assigns) do
    ~H"""
    <div class="dropdown" aria-expanded="false" id={@id}>
      <button class="dropdown__toggle" id={"#{@id}-toggle"} phx-click={toggle_dropdown(@id)}>
        <%= render_slot(@toggle) %>
      </button>
      <% # TODO add an id or something. the dropdown should be labelled by the content of the toggle %>
      <menu class="dropdown__menu list" id={"#{@id}-popover"} aria-labelledby="">
        <%= render_slot(@inner_block) %>
      </menu>
    </div>
    """
  end

  defp toggle_dropdown(id) do
    JS.toggle(to: "##{id}-popover")
  end

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
      |> assign(:size_class, icon_size_class(assigns[:size]))
      |> assign_new(:alt, fn -> nil end)

    ~H"""
    <svg
      class={["icon", @size_class, assigns[:class]]}
      fill="currentColor"
      role="img"
      aria-hidden={is_nil(@alt)}
      {@extra}
    >
      <%= if @alt do %>
        <title><%= @alt %></title>
      <% end %>
      <use href={sprite_url(@name)} />
    </svg>
    """
  end

  defp icon_size_class(nil), do: ""
  defp icon_size_class(size), do: "icon--size-#{size}"

  defp sprite_url(icon_name), do: Routes.static_path(Endpoint, "/assets/sprite.svg##{icon_name}")
end
