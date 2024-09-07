defmodule Storybook.CoreComponents.Anchor do
  use PhoenixStorybook.Story, :component

  def function, do: &AppWeb.CoreComponents.anchor/1

  def variations do
    [
      %Variation{
        id: :standalone,
        slots: [~s|This is an anchor|]
      }
    ]
  end
end
