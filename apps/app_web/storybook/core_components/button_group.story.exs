defmodule Storybook.CoreComponents.ButtonGroup do
  use PhoenixStorybook.Story, :component

  def function, do: &AppWeb.CoreComponents.button_group/1

  def imports, do: [{AppWeb.CoreComponents, button: 1, icon: 1}]

  def variations do
    [
      variation(id: :default, slots: [~s(<.button>Label</.button>)]),
      %VariationGroup{
        id: :multiple_buttons,
        variations: [
          variation(
            id: :two_secondary_buttons,
            slots: [
              ~s(<.button kind={:secondary}>Button 1</.button>),
              ~s(<.button kind={:secondary}>Button 2</.button>)
            ]
          ),
          variation(
            id: :one_primary_one_secondary_button,
            slots: [
              ~s(<.button kind={:secondary}>Button 2</.button>),
              ~s(<.button kind={:primary}>Button 1</.button>)
            ]
          )
        ]
      },
      %VariationGroup{
        id: :step_navigation,
        variations: [
          variation(
            id: :first_step,
            slots: [
              ~s(<.button kind={:ghost}>Continue <.icon name={:chevron_right} /></.button>)
            ]
          ),
          variation(
            id: :middle_step,
            attributes: %{class: "justify-between"},
            slots: [
              ~s(<.button kind={:ghost}><.icon name={:chevron_left} />Step back</.button>),
              ~s(<.button kind={:ghost}>Continue <.icon name={:chevron_right} /></.button>)
            ]
          ),
          variation(
            id: :last_step,
            attributes: %{class: "justify-between"},
            slots: [
              ~s(<.button kind={:ghost}><.icon name={:chevron_left} />Step back</.button>),
              ~s(<.button kind={:primary}>Finish</.button>)
            ]
          )
        ]
      }
    ]
  end

  defp variation(opts) do
    id = Keyword.fetch!(opts, :id)

    attributes =
      opts
      |> Keyword.get(:attributes, %{})
      |> Enum.into(%{
        style: "width: 20rem; border: 1px dotted #000; padding: 0.5rem;"
      })

    slots = Keyword.fetch!(opts, :slots)

    %Variation{
      id: id,
      attributes: attributes,
      slots: slots
    }
  end
end
