defmodule Storybook.CoreComponents.Tile do
  use PhoenixStorybook.Story, :component

  def function, do: &AppWeb.CoreComponents.tile/1

  def container, do: {:div, "data-background": "theme"}
  def imports, do: [{AppWeb.CoreComponents, button: 1, icon: 1}]

  def variations do
    [
      %Variation{
        id: :book,
        attributes: %{
          style: "width: 20rem"
        },
        slots: [
          """
          <span class="label grow leading-none line-clamp-2">Milano</span>
          <.button kind={:ghost}>
            Open
            <.icon name={:chevron_right} />
          </.button>
          """
        ]
      },
      %Variation{
        id: :balance,
        attributes: %{
          style: "width: 20rem"
        },
        slots: [
          """
          <div class="grid grid-rows-2 grid-cols-[1fr_1fr] items-center grid-flow-col">
            <div class="truncate">
              <span class="label text-theme-500">John Doe</span>
              owes
              <span class="label">Jane Doe</span>
            </div>
            <span class="label">330€</span>
            <.button kind={:ghost} class="row-span-2">
              Settle up
              <.icon name={:chevron_right} />
            </.button>
          </div>
          """
        ]
      },
      %Variation{
        id: :new_transfer,
        attributes: %{
          kind: :primary,
          style: "width: 20rem"
        },
        slots: [
          """
          <.icon name={:plus} />
          New payment
          """
        ]
      }
    ]
  end
end
