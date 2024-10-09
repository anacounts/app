defmodule Storybook.CoreComponents.List do
  use PhoenixStorybook.Story, :component

  def function, do: &AppWeb.CoreComponents.list/1

  def imports do
    [
      {AppWeb.CoreComponents,
       avatar: 1, button: 1, icon: 1, input: 1, list_item: 1, list_item_link: 1}
    ]
  end

  def variations do
    [
      %Variation{
        id: :members,
        attributes: %{
          style: "width: 20rem"
        },
        slots: [
          """
          <.list_item_link class="flex items-center gap-2">
            #{list_item_content("Caramel")}
            #{remove_button()}
          </.list_item_link>
          <.list_item_link class="flex items-center gap-2">
            #{list_item_content("Beursalé")}
            #{remove_button()}
          </.list_item_link>
          """
        ]
      },
      %Variation{
        id: :weights,
        attributes: %{
          style: "width: 20rem"
        },
        slots: [
          """
          <.list_item class="flex items-center gap-2">
            #{list_item_content("Caramel")}
            #{weight_input()}
          </.list_item>
          <.list_item class="flex items-center gap-2">
            #{list_item_content("Beursalé")}
            #{weight_input()}
          </.list_item>
          """
        ]
      }
    ]
  end

  defp list_item_content(name) do
    """
    <.avatar src="https://avatars.githubusercontent.com/u/1" alt="" />
    <span class="label grow">#{name}</span>
    """
  end

  defp remove_button do
    """
    <.button kind={:ghost}>
      Remove
      <.icon name={:chevron_right} />
    </.button>
    """
  end

  defp weight_input do
    """
    <.input
      type="number"
      name={}
      value="1"
      step="0.01"
      label_class="w-24 mb-0"
      class="w-full"
    />
    """
  end
end
