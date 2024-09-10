defmodule AppWeb.TransfersComponents do
  @moduledoc """
  This module contains all the components specific to transfers.
  """

  use AppWeb, :html

  alias App.Transfers.MoneyTransfer

  @doc """
  Transfer tiles are used to provide a quick glance at a transfer.
  """
  attr :transfer, MoneyTransfer, required: true

  attr :rest, :global

  slot :start,
    doc: """
    By default, an icon is displayed at the start of the tile to represent the transfer
    type. This icon can be overriden by using the `start` slot.
    """

  def transfer_tile(assigns) do
    ~H"""
    <div class={["tile pr-4", transfer_type_color_class(@transfer.type)]} {@rest}>
      <%= render_slot(@start, @transfer) || transfer_icon(assigns) %>
      <span class="label text-left grow">
        <%= @transfer.label %>
      </span>
      <.transfer_amount transfer={@transfer} />
    </div>
    """
  end

  defp transfer_type_color_class(:payment), do: "bg-red-100 text-red-500"
  defp transfer_type_color_class(:income), do: "bg-green-100 text-green-500"
  defp transfer_type_color_class(:reimbursement), do: "bg-neutral-100 text-neutral-500"

  @doc """
  Transfer icons are based on the transfer type.

  They may be used in the transfer tile to visually represent the type of transfer.
  """
  def transfer_icon(assigns) do
    ~H"<.icon name={transfer_type_icon(@transfer.type)} />"
  end

  def transfer_type_icon(:payment), do: :minus
  def transfer_type_icon(:income), do: :plus
  def transfer_type_icon(:reimbursement), do: :arrow_right

  attr :transfer, MoneyTransfer, required: true

  defp transfer_amount(assigns) do
    assigns = assign(assigns, :sign, transfer_sign(assigns.transfer.type))

    ~H|<span class="label"><%= @sign <> Money.to_string!(@transfer.amount) %></span>|
  end

  defp transfer_sign(:payment), do: "-"
  defp transfer_sign(:income), do: "+"
  defp transfer_sign(:reimbursement), do: ""
end
