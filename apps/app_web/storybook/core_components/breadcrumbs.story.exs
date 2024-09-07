defmodule Storybook.CoreComponents.Breadcrumbs do
  use PhoenixStorybook.Story, :component

  def function, do: &AppWeb.CoreComponents.breadcrumb/1

  def imports,
    do: [{AppWeb.CoreComponents, breadcrumb_home: 1, breadcrumb_item: 1, breadcrumb_ellipsis: 1}]

  def variations do
    [
      %Variation{
        id: :default,
        attributes: %{
          "aria-label" => "Breadcrumb"
        },
        slots: [
          """
          <.breadcrumb_home navigate="/storybook" alt="Home" />
          <.breadcrumb_item navigate="/storybook/core_components/breadcrumb">
            Core Components
          </.breadcrumb_item>
          <.breadcrumb_item>
            Breadcrumbs
          </.breadcrumb_item>
          """
        ]
      },
      %Variation{
        id: :ellipsis,
        attributes: %{
          "aria-label" => "Breadcrumb"
        },
        slots: [
          """
          <.breadcrumb_home navigate="/storybook" alt="Home" />
          <.breadcrumb_ellipsis />
          <.breadcrumb_item navigate="/storybook/core_components/breadcrumb">
            Core Components
          </.breadcrumb_item>
          <.breadcrumb_item>
            Breadcrumbs
          </.breadcrumb_item>
          """
        ]
      },
      %Variation{
        id: :long_item,
        attributes: %{
          "aria-label" => "Breadcrumb"
        },
        slots: [
          """
          <.breadcrumb_home navigate="/storybook" alt="Home" />
          <.breadcrumb_item navigate="/storybook/core_components/breadcrumb">
            Quisquam excepturi consequuntur aperiam et.
            Temporibus in ut qui commodi perferendis.
            Similique sunt optio accusantium mollitia
          </.breadcrumb_item>
          <.breadcrumb_item>
            Label
          </.breadcrumb_item>
          """
        ]
      }
    ]
  end
end
