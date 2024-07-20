defmodule Storybook.CoreComponents.Button do
  use PhoenixStorybook.Story, :component

  def function, do: &AppWeb.CoreComponents.button/1

  def variations do
    [
      %Variation{
        id: :default,
        attributes: %{
          color: :feature
        },
        slots: ["Label"]
      },
      %VariationGroup{
        id: :cta,
        description: "Call to action (color)",
        variations: [
          %Variation{
            id: :cta_default,
            attributes: %{
              color: :cta
            },
            slots: ["Label"]
          },
          %Variation{
            id: :cta_disabled,
            attributes: %{
              color: :cta,
              disabled: true
            },
            slots: ["Label"]
          }
        ]
      },
      %VariationGroup{
        id: :feature,
        description: "Feature (color)",
        variations: [
          %Variation{
            id: :feature_default,
            attributes: %{
              color: :feature
            },
            slots: ["Label"]
          },
          %Variation{
            id: :feature_disabled,
            attributes: %{
              color: :feature,
              disabled: true,
            },
            slots: ["Label"]
          }
        ]
      },
      %VariationGroup{
        id: :ghost,
        description: "Ghost (color)",
        variations: [
          %Variation{
            id: :ghost_default,
            attributes: %{
              color: :ghost
            },
            slots: ["Label"]
          },
          %Variation{
            id: :ghost_disabled,
            attributes: %{
              color: :ghost,
              disabled: true
            },
            slots: ["Label"]
          }
        ]
      },
      %VariationGroup{
        id: :icons,
        variations: [
          %Variation{
            id: :icon_start,
            attributes: %{
              color: :feature
            },
            slots: [~s|<.icon name="person-add" /> Label|]
          },
          %Variation{
            id: :icon_end,
            attributes: %{
              color: :feature
            },
            slots: [~s|Label <.icon name="arrow_downward" />|]
          },
          %Variation{
            id: :icon_both,
            attributes: %{
              color: :feature
            },
            slots: [~s|<.icon name="person-add" /> Label <.icon name="arrow_downward" />|]
          },
          %Variation{
            id: :icon_only,
            attributes: %{
              color: :feature
            },
            slots: [~s|<.icon name="person-add" />|]
          },
        ]
      }
    ]
  end
end
