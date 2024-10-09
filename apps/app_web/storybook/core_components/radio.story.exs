defmodule Storybook.CoreComponents.Radio do
  use PhoenixStorybook.Story, :component

  def function, do: &AppWeb.CoreComponents.radio/1

  def variations do
    [
      %Variation{
        id: :default
      },
      %Variation{
        id: :checked,
        attributes: %{checked: true}
      },
      %Variation{
        id: :disabled,
        attributes: %{disabled: true}
      },
      %Variation{
        id: :checked_disabled,
        attributes: %{checked: true, disabled: true}
      }
    ]
  end
end
