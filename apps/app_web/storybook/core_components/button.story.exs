defmodule Storybook.CoreComponents.Button do
  use PhoenixStorybook.Story, :component

  def function, do: &AppWeb.CoreComponents.button/1

  def imports, do: [{AppWeb.CoreComponents, icon: 1}]

  def variations do
    [
      variation(id: :default),
      %VariationGroup{
        id: :cta,
        description: "Call to action (color)",
        variations: [
          variation(
            id: :cta_default,
            attributes: %{color: :cta}
          ),
          variation(
            id: :cta_disabled,
            attributes: %{color: :cta, disabled: true}
          )
        ]
      },
      %VariationGroup{
        id: :feature,
        description: "Feature (color)",
        variations: [
          variation(
            id: :feature_default,
            attributes: %{color: :feature}
          ),
          variation(
            id: :feature_disabled,
            attributes: %{color: :feature, disabled: true}
          )
        ]
      },
      %VariationGroup{
        id: :ghost,
        description: "Ghost (color)",
        variations: [
          variation(
            id: :ghost_default,
            attributes: %{color: :ghost}
          ),
          variation(
            id: :ghost_disabled,
            attributes: %{color: :ghost, disabled: true}
          )
        ]
      },
      %VariationGroup{
        id: :icons,
        variations: [
          variation(
            id: :icon_start,
            attributes: %{style: nil},
            slots: [~s|<.icon name="person-add" /> Label|]
          ),
          variation(
            id: :icon_end,
            attributes: %{style: nil},
            slots: [~s|Label <.icon name="arrow_downward" />|]
          ),
          variation(
            id: :icon_both,
            attributes: %{style: nil},
            slots: [~s|<.icon name="person-add" /> Label <.icon name="arrow_downward" />|]
          ),
          variation(
            id: :icon_only,
            attributes: %{style: nil},
            slots: [~s|<.icon name="person-add" />|]
          )
        ]
      },
      %VariationGroup{
        id: :multiline,
        variations: [
          variation(
            id: :two_lines,
            slots: ["This label spans two lines"]
          ),
          variation(
            id: :overflowing,
            slots: [
              ~s|<span class="line-clamp-2">This very long label spans more lines yet</span>|
            ]
          )
        ]
      }
    ]
  end

  defp variation(opts) do
    id = Keyword.fetch!(opts, :id)
    description = Keyword.get(opts, :description)

    attributes =
      opts
      |> Keyword.get(:attributes, %{})
      |> Enum.into(%{
        color: :feature,
        style: "width: 10rem;"
      })

    slots = Keyword.get(opts, :slots, ["Label"])

    %Variation{
      id: id,
      description: description,
      attributes: attributes,
      slots: slots
    }
  end
end
