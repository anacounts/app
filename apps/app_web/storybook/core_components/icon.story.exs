defmodule Storybook.CoreComponents.Icon do
  use PhoenixStorybook.Story, :component

  def function, do: &AppWeb.CoreComponents.icon/1

  def variations do
    [
      %Variation{
        id: :standalone,
        attributes: %{name: :home}
      }
    ]
  end
end
