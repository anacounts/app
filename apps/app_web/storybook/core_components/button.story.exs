defmodule Storybook.CoreComponents.Button do
  use PhoenixStorybook.Story, :component

  def function, do: &AppWeb.CoreComponents.button/1

  def variations do
    [
      %Variation{
        id: :most_common,
        description: "Default button",
        attributes: %{
          color: :feature
        },
        slots: ["Feature button"]
      },
      %VariationGroup{
        id: :colors,
        description: "Button colors",
        variations: [
          %Variation{
            id: :cta,
            attributes: %{
              color: :cta
            },
            slots: ["Call to action"]
          },
          %Variation{
            id: :feature,
            attributes: %{
              color: :feature
            },
            slots: ["Feature button"]
          },
          %Variation{
            id: :ghost,
            attributes: %{
              color: :ghost
            },
            slots: ["Ghost button"]
          }
        ]
      }
    ]
  end
end
