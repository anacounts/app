defmodule Storybook.CoreComponents.Select do
  use PhoenixStorybook.Story, :component

  def function, do: &AppWeb.CoreComponents.select/1

  def variations do
    [
      variation(id: :default),
      variation(
        id: :prompt,
        attributes: %{prompt: "Choose a color..."}
      ),
      variation(
        id: :default_value,
        attributes: %{value: "Green"}
      ),
      variation(
        id: :disabled,
        attributes: %{disabled: true}
      ),
      variation(
        id: :error,
        attributes: %{error: true}
      )
    ]
  end

  defp variation(opts) do
    id = Keyword.fetch!(opts, :id)

    attributes =
      opts
      |> Keyword.get(:attributes, %{})
      |> Enum.into(%{
        options: ["Red", "Green", "Blue"],
        style: "width: 10rem;"
      })

    %Variation{
      id: id,
      attributes: attributes
    }
  end
end
