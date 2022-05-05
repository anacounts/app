defmodule AnacountsAPI.Middlewares.HandleChangesetErrors do
  @moduledoc """
  A middleware that enables mutations to return `{:error, %Ecto.Changeset{}}`.
  Treats, translates and format errors before sending them back.

  Enabled by overriding the `middleware` callback in the main schema.
  """

  @behaviour Absinthe.Middleware
  def call(resolution, _opts) do
    %{resolution | errors: Enum.flat_map(resolution.errors, &handle_error/1)}
  end

  defp handle_error(%Ecto.Changeset{} = changeset) do
    changeset
    |> Ecto.Changeset.traverse_errors(&translate_error/1)
    |> Enum.map(fn
      {field, errors} when is_list(errors) ->
        "#{field}: #{Enum.join(errors, "; ")}"

      {field, error} ->
        "#{field}: #{error}"
    end)
  end

  defp handle_error(error), do: [error]

  # Translates an error message using gettext.
  defp translate_error({msg, opts}) do
    # When using gettext, we typically pass the strings we want
    # to translate as a static argument:
    #
    #     # Translate "is invalid" in the "errors" domain
    #     dgettext("errors", "is invalid")
    #
    #     # Translate the number of files with plural rules
    #     dngettext("errors", "1 file", "%{count} files", count)
    #
    # Because the error messages we show in our forms and APIs
    # are defined inside Ecto, we need to translate them dynamically.
    # This requires us to call the Gettext module passing our gettext
    # backend as first argument.
    #
    # Note we use the "errors" domain, which means translations
    # should be written to the errors.po file. The :count option is
    # set by Ecto and indicates we should also apply plural rules.
    if count = opts[:count] do
      Gettext.dngettext(AnacountsAPI.Gettext, "errors", msg, msg, count, opts)
    else
      Gettext.dgettext(AnacountsAPI.Gettext, "errors", msg, opts)
    end
  end
end
