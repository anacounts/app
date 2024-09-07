defmodule Storybook.CoreComponents.Button do
  use PhoenixStorybook.Story, :component

  def function, do: &AppWeb.CoreComponents.button/1

  def imports, do: [{AppWeb.CoreComponents, icon: 1}]

  def variations do
    [
      variation(id: :default),
      %VariationGroup{
        id: :primary,
        variations: [
          variation(
            id: :primary_default,
            attributes: %{kind: :primary}
          ),
          variation(
            id: :primary_disabled,
            attributes: %{kind: :primary, disabled: true}
          )
        ]
      },
      %VariationGroup{
        id: :secondary,
        variations: [
          variation(
            id: :secondary_default,
            attributes: %{kind: :secondary}
          ),
          variation(
            id: :secondary_disabled,
            attributes: %{kind: :secondary, disabled: true}
          )
        ]
      },
      %VariationGroup{
        id: :ghost,
        variations: [
          variation(
            id: :ghost_default,
            attributes: %{kind: :ghost}
          ),
          variation(
            id: :ghost_disabled,
            attributes: %{kind: :ghost, disabled: true}
          )
        ]
      },
      %VariationGroup{
        id: :icons,
        variations: [
          variation(
            id: :icon_start,
            attributes: %{style: nil},
            slots: [~s|<.icon name={:user_plus} /> Label|]
          ),
          variation(
            id: :icon_end,
            attributes: %{style: nil},
            slots: [~s|Label <.icon name={:chevron_down} />|]
          )
        ]
      },
      variation(
        id: :navigation,
        attributes: %{navigate: "#"}
      ),
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
        kind: :secondary,
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
