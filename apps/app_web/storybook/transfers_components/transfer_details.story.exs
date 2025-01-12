defmodule Storybook.TransfersComponents.TransferDetails do
  alias App.Transfers.Peer
  use PhoenixStorybook.Story, :component

  alias App.Books.BookMember
  alias App.Transfers.MoneyTransfer
  alias App.Transfers.Peer

  def function, do: &AppWeb.TransfersComponents.transfer_details/1

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
                amount: Money.new(:EUR, "333.33"),
                date: ~D[2021-01-01],
                tenant: %BookMember{
                  nickname: "Jane Doe"
                },
                peers: [%Peer{}, %Peer{}],
                balance_means: :weight_by_income
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
                amount: Money.new(:EUR, "333.33"),
                date: ~D[2021-02-15],
                tenant: %BookMember{
                  nickname: "Jane Doe"
                },
                peers: [%Peer{}, %Peer{}],
                balance_means: :divide_equally
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
                amount: Money.new(:EUR, "333.33"),
                date: ~D[2021-03-30],
                tenant: %BookMember{
                  nickname: "Jane Doe"
                },
                peers: [%Peer{member: %BookMember{nickname: "John Doe"}}]
              },
              style: "width: 20rem"
            }
          }
        ]
      }
    ]
  end
end
