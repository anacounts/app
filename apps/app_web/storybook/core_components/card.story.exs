defmodule Storybook.CoreComponents.Card do
  use PhoenixStorybook.Story, :component

  def function, do: &AppWeb.CoreComponents.card/1

  def container, do: {:div, "data-background": "theme"}
  def imports, do: [{AppWeb.CoreComponents, icon: 1}]

  def variations do
    [
      variation(
        id: :default,
        slots: [
          ~s|<:title>Joined on</:title>|,
          ~s|July 6, 2024|
        ]
      ),
      %VariationGroup{
        id: :links,
        variations: [
          variation(
            id: :profile,
            slots: [
              ~s|<:title>My profile <.icon name={:chevron_right} /></:title>|,
              ~s|Nickname|
            ]
          ),
          variation(
            id: :members,
            slots: [
              ~s|<:title>Members <.icon name={:chevron_right} /></:title>|,
              """
              <div class="flex justify-center items-center">5 <.icon name={:user} /></div>
              <div class="text-sm">2 unlinked</div>
              """
            ]
          )
        ]
      },
      %VariationGroup{
        id: :colors,
        variations: [
          variation(
            id: :positive,
            attributes: %{color: :green},
            slots: [
              ~s|<:title>Balance <.icon name={:chevron_right} /></:title>|,
              ~s|+333.33€|
            ]
          ),
          variation(
            id: :negative,
            attributes: %{color: :red},
            slots: [
              ~s|<:title>Balance <.icon name={:chevron_right} /></:title>|,
              ~s|-333.33€|
            ]
          ),
          variation(
            id: :undefined,
            attributes: %{color: :neutral},
            slots: [
              ~s|<:title>Balance <.icon name={:chevron_right} /></:title>|,
              ~s|XX.XX€|
            ]
          )
        ]
      },
      variation(
        id: :complex_content,
        attributes: %{
          style: "width: 20rem"
        },
        # TODO(v2,transfer tile) replace by actual transfer tile component
        slots: [
          ~s|<:title>Latest transfers <.icon name={:chevron_right} /></:title>|,
          """
          <div class="mb-2 p-2 rounded-component bg-red-100 text-red-500 flex items-center gap-2">
            <.icon name={:minus} />
            <span class="text-base font-bold text-left grow">Housing</span>
            <span class="text-base font-bold">-33.33€</span>
          </div>
          <div class="mb-2 p-2 rounded-component bg-neutral-100 text-neutral-500 flex items-center gap-2">
            <.icon name={:arrow_right} />
            <span class="text-base font-bold text-left grow">Reimbursement</span>
            <span class="text-base font-bold">+33.33€</span>
          </div>
          <div class="mb-2 p-2 rounded-component bg-green-100 text-green-500 flex items-center gap-2">
            <.icon name={:plus} />
            <span class="text-base font-bold text-left grow">Overcharge</span>
            <span class="text-base font-bold">+33.33€</span>
          </div>
          """
        ]
      )
    ]
  end

  defp variation(opts) do
    id = Keyword.fetch!(opts, :id)
    slots = Keyword.fetch!(opts, :slots)

    attributes =
      opts
      |> Keyword.get(:attributes, %{})
      |> Enum.into(%{
        style: "width: 10rem;",
        color: :secondary
      })

    %Variation{
      id: id,
      attributes: attributes,
      slots: slots
    }
  end
end
