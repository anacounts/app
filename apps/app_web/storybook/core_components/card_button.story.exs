defmodule Storybook.CoreComponents.CardButton do
  use PhoenixStorybook.Story, :component

  def function, do: &AppWeb.CoreComponents.card_button/1

  def container, do: {:div, "data-background": "theme"}
  def imports, do: [{AppWeb.CoreComponents, icon: 1}]

  def variations do
    [
      %Variation{
        id: :invite_people,
        attributes: %{
          icon: :envelope,
          color: :primary
        },
        slots: [
          ~s|Invite people|
        ]
      },
      %Variation{
        id: :create_manually,
        attributes: %{
          icon: :user_plus,
          color: :secondary
        },
        slots: [
          ~s|Create manually|
        ]
      },
      %Variation{
        id: :new_transfer,
        attributes: %{
          icon: :arrows_right_left,
          class: "aspect-square"
        },
        slots: [
          ~s|New transfer|
        ]
      }
    ]
  end
end
