defmodule Storybook.CoreComponents.Card do
  use PhoenixStorybook.Story, :component

  def function, do: &AppWeb.CoreComponents.card/1

  def container, do: {:div, "data-background": "theme"}

  def imports do
    [
      {AppWeb.CoreComponents, icon: 1},
      {AppWeb.TransfersComponents, transfer_tile: 1}
    ]
  end

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
              ~s|XX.XX|
            ]
          )
        ]
      },
      variation(
        id: :complex_content,
        attributes: %{
          style: "width: 20rem"
        },
        slots: [
          ~s|<:title>Latest transfers <.icon name={:chevron_right} /></:title>|,
          """
          <div class="space-y-2">
            <%= for transfer <- [
              %App.Transfers.MoneyTransfer{type: :payment, label: "Housing", amount: Money.new(:EUR, "333.33")},
              %App.Transfers.MoneyTransfer{type: :income, label: "Overcharge", amount: Money.new(:EUR, "333.33")},
              %App.Transfers.MoneyTransfer{type: :reimbursement, label: "Reimbursement", amount: Money.new(:EUR, "333.33")}
            ] do %>
              <.transfer_tile transfer={transfer} />
            <% end %>
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
