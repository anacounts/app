defmodule Storybook.CoreComponents.Typography do
  use PhoenixStorybook.Story, :page

  def doc, do: "Typography"

  def render(assigns) do
    ~H"""
    <p class="title-1">Title 1</p>

    <p class="title-2">Title 2</p>

    <p class="label">Label</p>

    <p class="paragraph">
      Odio eaque eius ut rerum aliquam. Sunt vel modi reiciendis et. Quod nesciunt sit
      reiciendis iste ex. Voluptates harum sunt quo non quod commodi. Voluptatem neque
      quam nihil.
    </p>
    """
  end
end
