defmodule AppWeb.BalanceConfigLive do
  use AppWeb, :live_view

  alias App.Balance.BalanceConfig
  alias App.Balance.BalanceConfigs

  def render(assigns) do
    ~H"""
    <.page_header>
      <:title><%= gettext("Balance Settings") %></:title>
    </.page_header>

    <.alert :for={{type, message} <- @flash} type={type}><%= message %></.alert>

    <.form for={@form} id="balance_config_form" phx-change="validate" phx-submit="save" class="mx-4">
      <.input
        field={@form[:annual_income]}
        type="number"
        label={gettext("Last year incomes")}
        min="0.00"
      />

      <p>
        <%= gettext(
          "Indicate your income from last year. To do so, we adivise you to go on " <>
            "your bank website, and sum all incomes from 1 year ago to today."
        ) %>
      </p>

      <.button color={:cta} phx-disable-with={gettext("Saving...")}>
        <%= gettext("Save") %>
      </.button>
    </.form>
    """
  end

  def mount(_params, _session, socket) do
    form =
      socket.assigns.current_user
      |> BalanceConfigs.get_user_balance_config_or_default()
      |> BalanceConfigs.change_balance_config()

    {:ok, assign(socket, form: to_form(form), page_title: gettext("Balance Settings")),
     temporary_assigns: [form: form, page_title: nil]}
  end

  def handle_event("validate", params, socket) do
    %{"balance_config" => balance_config_params} = params
    form = BalanceConfigs.change_balance_config(%BalanceConfig{}, balance_config_params)

    {:noreply, assign(socket, form: to_form(form))}
  end

  def handle_event("save", params, socket) do
    %{"balance_config" => balance_config_params} = params
    user = socket.assigns.current_user

    balance_config = BalanceConfigs.get_user_balance_config_or_default(user)

    case BalanceConfigs.update_user_balance_config(user, balance_config, balance_config_params) do
      {:ok, _balance_config} ->
        {:noreply,
         socket
         |> put_flash(:info, gettext("Balance settings updated"))
         |> redirect(to: ~p"/users/settings")}

      {:error, form} ->
        {:noreply, assign(socket, form: to_form(form))}
    end
  end
end
