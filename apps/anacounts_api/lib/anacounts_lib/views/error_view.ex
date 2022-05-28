defmodule AnacountsAPI.ErrorView do
  @send_error_details Application.compile_env(
                        :anacounts_api,
                        [AnacountsAPI.Endpoint, :send_error_details],
                        false
                      )

  def render(template, assigns) do
    %{
      "errors" => [
        %{
          "locations" => [%{"column" => -1, "line" => -1}],
          "message" => Phoenix.Controller.status_message_from_template(template)
        }
        |> maybe_add_details(@send_error_details, assigns)
      ]
    }
  end

  defp maybe_add_details(error, true, %{stack: stack, reason: reason}) do
    Map.merge(error, %{
      "reason" => inspect(reason),
      "stack" => inspect(stack)
    })
  end

  defp maybe_add_details(error, false, _assigns), do: error
end
