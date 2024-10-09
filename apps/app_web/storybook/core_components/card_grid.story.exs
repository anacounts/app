defmodule Storybook.CoreComponents.CardGrid do
  use PhoenixStorybook.Story, :component

  def function, do: &AppWeb.CoreComponents.card_grid/1

  def container, do: {:div, "data-background": "theme"}

  def imports do
    [
      {AppWeb.CoreComponents, icon: 1, card: 1, card_button: 1},
      {AppWeb.TransfersComponents, transfer_tile: 1}
    ]
  end

  def variations do
    [
      %Variation{
        id: :book,
        slots: [
          """
          <.link href="#">
            <.card>
              <:title>My profile <.icon name={:chevron_right} /></:title>
              Nickname
            </.card>
          </.link>
          <.link href="#">
            <.card color={:green}>
              <:title>Balance <.icon name={:chevron_right} /></:title>
              +333.33€
            </.card>
          </.link>
          <.link href="#" class="col-span-2">
            <.card>
              <:title>Latest transfers <.icon name={:chevron_right} /></:title>
              <div class="space-y-2">
                <%= for transfer <- [
                  %App.Transfers.MoneyTransfer{type: :payment, label: "Housing", amount: Money.new(:EUR, "333.33")},
                  %App.Transfers.MoneyTransfer{type: :income, label: "Overcharge", amount: Money.new(:EUR, "333.33")},
                  %App.Transfers.MoneyTransfer{type: :reimbursement, label: "Reimbursement", amount: Money.new(:EUR, "333.33")}
                ] do %>
                  <.transfer_tile transfer={transfer} />
                <% end %>
              </div>
            </.card>
          </.link>
          <.link href="#">
            <.card_button icon={:arrows_right_left} class="h-24">
              New payment
            </.card_button>
          </.link>
          <.link href="#">
            <.card class="h-24">
              <:title>Members <.icon name={:chevron_right} /></:title>
              <div class="flex justify-center items-center">5 <.icon name={:user} /></div>
              <div class="text-sm">2 unlinked</div>
            </.card>
          </.link>
          <.link href="#">
            <.card_button icon={:cog_6_tooth} class="h-24">
              Configuration
            </.card_button>
          </.link>
          """
        ]
      }
    ]
  end
end
