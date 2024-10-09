defmodule Storybook.CoreComponents.TextInput do
  use PhoenixStorybook.Story, :component

  def function, do: &AppWeb.CoreComponents.text_input/1

  def imports, do: [{AppWeb.CoreComponents, icon: 1}]

  def variations do
    [
      %Variation{
        id: :default
      },
      %Variation{
        id: :placeholder,
        attributes: %{placeholder: "Placeholder"}
      },
      %Variation{
        id: :disabled,
        attributes: %{disabled: true, value: "Disabled"}
      },
      %Variation{
        id: :error,
        attributes: %{error: true}
      },
      %VariationGroup{
        id: :addons,
        variations: [
          %Variation{
            id: :prefix,
            attributes: %{prefix: :bookmark}
          },
          %Variation{
            id: :suffix,
            attributes: %{suffix: :currency_euro}
          },
          %Variation{
            id: :prefix_and_suffix,
            attributes: %{prefix: :bookmark, suffix: :currency_euro}
          },
          %Variation{
            id: :disabled_addons,
            attributes: %{disabled: true, prefix: :bookmark, suffix: :currency_euro}
          }
        ]
      }
    ]
  end
end
