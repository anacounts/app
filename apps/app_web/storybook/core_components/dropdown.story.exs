defmodule Storybook.CoreComponents.Divider do
  use PhoenixStorybook.Story, :component

  def function, do: &AppWeb.CoreComponents.dropdown/1

  def imports,
    do: [{AppWeb.CoreComponents, button: 1, checkbox: 1, icon: 1, list: 1, list_item: 1}]

  def variations do
    [
      %Variation{
        id: :default,
        slots: [
          """
          <:trigger :let={attrs}>
            <.button kind={:secondary} {attrs}>
              Dropdown
              <.icon name={:chevron_down} />
            </.button>
          </:trigger>

          <.button kind={:ghost}>
            Button 1
          </.button>
          <.button kind={:ghost}>
            Button 2
            <.icon name={:chevron_down} class="ms-auto" />
          </.button>
          <.button kind={:ghost}>
            <.icon name={:cog_6_tooth} />
            Button 3
          </.button>
          """
        ]
      },
      %Variation{
        id: :checkboxes,
        slots: [
          """
          <:trigger :let={attrs}>
            <.button kind={:secondary} {attrs}>
              Filter
              <.icon name={:chevron_down} />
            </.button>
          </:trigger>

          <.list>
            <.list_item :for={idx <- 1..3}>
              <label class="form-control-container justify-between">
                <span class="label">Filter <%= idx %></span>
                <.checkbox id={"filter-\#{idx}"} />
              </label>
            </.list_item>
          </.list>
          """
        ]
      }
    ]
  end
end
