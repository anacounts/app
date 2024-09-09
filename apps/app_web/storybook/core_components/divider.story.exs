defmodule Storybook.CoreComponents.Divider do
  use PhoenixStorybook.Story, :component

  def function, do: &AppWeb.CoreComponents.divider/1

  def variations do
    [
      %Variation{
        id: :default,
        attributes: %{
          style: "width: 10rem"
        }
      }
    ]
  end
end
