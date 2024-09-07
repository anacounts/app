defmodule Storybook.CoreComponents.Avatar do
  use PhoenixStorybook.Story, :component

  def function, do: &AppWeb.CoreComponents.avatar/1

  def variations do
    [
      %Variation{
        id: :small,
        attributes: %{
          src: "https://avatars.githubusercontent.com/u/1",
          alt: "Small sized avatar"
        }
      },
      %Variation{
        id: :hero,
        attributes: %{
          src: "https://avatars.githubusercontent.com/u/1",
          alt: "Hero sized avatar",
          size: :hero
        }
      }
    ]
  end
end
