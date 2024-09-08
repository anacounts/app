defmodule Storybook.CoreComponents.CardGrid do
  use PhoenixStorybook.Story, :component

  def function, do: &AppWeb.CoreComponents.card_grid/1

  def container, do: {:div, "data-background": "theme"}
  def imports, do: [{AppWeb.CoreComponents, icon: 1, card: 1, card_button: 1}]

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
              <% # TODO(v2,transfer tile) replace by actual transfer tile component %>
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
            </.card>
          </.link>
          <.link href="#">
            <.card_button icon={:arrows_right_left} class="h-24">
              New transfer
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
