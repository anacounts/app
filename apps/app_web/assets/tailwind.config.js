// See the Tailwind configuration guide for advanced usage
// https://tailwindcss.com/docs/configuration

const plugin = require("tailwindcss/plugin");
const defaultTheme = require("tailwindcss/defaultTheme");

module.exports = {
  content: ["./js/**/*.js", "../lib/*_web.ex", "../lib/*_web/**/*.*ex"],
  theme: {
    colors: {
      // Theme colors
      theme: {
        darker: "#cc3000",
        DEFAULT: "#ff3d00",
        lighter: "#ff501a",
        contrast: "#ffffff",
      },
      // Action colors
      action: {
        DEFAULT: "#485fc7",
      },
      // Gray colors
      white: "#ffffff",
      gray: {
        5: "#f8f9fa",
        10: "#f1f3f4",
        20: "#e9ecef",
        30: "#dadce0",
        40: "#c6c8ce",
        50: "#9aa0a6",
        60: "#80868b",
        70: "#5f6368",
        80: "#3c4043",
        90: "#202124",
      },
      black: "#000000",
      background: "#f8f9fa",
      // Status colors
      info: "#0b61ec",
      error: "#cd0000",
      // Helper colors
      transparent: "transparent",
      current: "currentColor",
    },
    extend: {
      fontFamily: {
        sans: ["Lato", ...defaultTheme.fontFamily.sans],
      },
    },
  },
  plugins: [
    require("@tailwindcss/typography"),
    plugin(({ addVariant }) =>
      addVariant("phx-no-feedback", [".phx-no-feedback&", ".phx-no-feedback &"])
    ),
    plugin(({ addVariant }) =>
      addVariant("phx-click-loading", [
        ".phx-click-loading&",
        ".phx-click-loading &",
      ])
    ),
    plugin(({ addVariant }) =>
      addVariant("phx-submit-loading", [
        ".phx-submit-loading&",
        ".phx-submit-loading &",
      ])
    ),
    plugin(({ addVariant }) =>
      addVariant("phx-change-loading", [
        ".phx-change-loading&",
        ".phx-change-loading &",
      ])
    ),
  ],
};
