defmodule AppWeb.Storybook do
  @moduledoc """
  Configuration for the Phoenix Storybook integration.
  """

  use PhoenixStorybook,
    otp_app: :app_web,
    content_path: Path.expand("../../storybook", __DIR__),
    # assets path are remote path, not local file-system paths
    css_path: "/assets/storybook.css",
    js_path: "/assets/storybook.js",
    sandbox_class: "app-web",
    title: "Anacounts Storybook",
    # Set the compilation mode to `:lazy`. The storybook is only used in
    # development, so we don't want to compile the files for nothing
    # in test and production.
    compilation_mode: :lazy
end
