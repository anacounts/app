defmodule Storybook.CoreComponents.Alert do
  use PhoenixStorybook.Story, :component

  def function, do: &AppWeb.CoreComponents.alert/1

  def imports, do: [{AppWeb.CoreComponents, icon: 1}]

  def variations do
    [
      %Variation{
        id: :error,
        attributes: %{
          kind: :error,
          style: "width: 20rem"
        },
        slots: [~s|Some information is missing to balance the book|]
      },
      %Variation{
        id: :warning,
        attributes: %{
          kind: :warning,
          style: "width: 20rem"
        },
        slots: [
          """
          <span class="grow">Your revenues are not set</span>
          <.icon name={:chevron_right} />
          """
        ]
      }
    ]
  end
end
