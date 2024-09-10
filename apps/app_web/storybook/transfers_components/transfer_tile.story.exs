defmodule Storybook.TransfersComponents.TransferTile do
  use PhoenixStorybook.Story, :component

  alias App.Transfers.MoneyTransfer

  def function, do: &AppWeb.TransfersComponents.transfer_tile/1

  def imports do
    [
      {AppWeb.TransfersComponents, transfer_icon: 1},
      {AppWeb.CoreComponents, input: 1}
    ]
  end

  def variations do
    [
      %VariationGroup{
        id: :latest_transfers,
        variations: [
          %Variation{
            id: :payment,
            attributes: %{
              transfer: %MoneyTransfer{
                type: :payment,
                label: "Housing",
                amount: Money.new(:EUR, "333.33")
              },
              style: "width: 20rem"
            }
          },
          %Variation{
            id: :income,
            attributes: %{
              transfer: %MoneyTransfer{
                type: :income,
                label: "Overcharge",
                amount: Money.new(:EUR, "333.33")
              },
              style: "width: 20rem"
            }
          },
          %Variation{
            id: :reimbursement,
            attributes: %{
              transfer: %MoneyTransfer{
                type: :reimbursement,
                label: "Reimbursement",
                amount: Money.new(:EUR, "333.33")
              },
              style: "width: 20rem"
            }
          }
        ]
      },
      %VariationGroup{
        id: :select_for_balance,
        variations: [
          %Variation{
            id: :not_selected,
            attributes: %{
              transfer: %MoneyTransfer{
                type: :payment,
                label: "Housing",
                amount: Money.new(:EUR, "333.33")
              },
              style: "width: 20rem"
            },
            slots: [
              ~s|<:start><.input type="checkbox" name={} value={} label_class="mb-0" /></:start>|
            ]
          },
          %Variation{
            id: :selected,
            attributes: %{
              transfer: %MoneyTransfer{
                type: :payment,
                label: "Housing",
                amount: Money.new(:EUR, "333.33")
              },
              style: "width: 20rem"
            },
            slots: [
              ~s|<:start><.input type="checkbox" checked name={} value={} label_class="mb-0" /></:start>|
            ]
          },
          %Variation{
            id: :force_selected,
            attributes: %{
              transfer: %MoneyTransfer{
                type: :payment,
                label: "Housing",
                amount: Money.new(:EUR, "333.33")
              },
              style: "width: 20rem"
            },
            slots: [
              ~s|<:start><.input type="checkbox" checked disabled name={} value={} label_class="mb-0" /></:start>|
            ]
          }
        ]
      }
    ]
  end
end
