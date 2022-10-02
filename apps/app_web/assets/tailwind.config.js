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
        darker: "#e63700",
        DEFAULT: "#ff3d00",
        lighter: "#ff501a",
        contrast: "#ffffff",
      },
      // Action colors
      action: {
        DEFAULT: "#0000ee",
      },
      // Gray colors
      white: "#ffffff",
      gray: {
        10: "#f7fafc",
        20: "#edf2f7",
        30: "#e2e8f0",
        40: "#cbd5e0",
        50: "#a0aec0",
        60: "#718096",
        70: "#4a5568",
        80: "#2d3748",
        90: "#1a202c",
      },
      black: "#000000",
      background: {
        DEFAULT: "#fff",
        2: "#f7fafc",
      },
      // Status colors
      info: "#0b61ec",
      success: "#4caf50",
      error: "#f1353a",
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
      addVariant("phx-no-feedback", ["&.phx-no-feedback", ".phx-no-feedback &"])
    ),
    plugin(({ addVariant }) =>
      addVariant("phx-click-loading", [
        "&.phx-click-loading",
        ".phx-click-loading &",
      ])
    ),
    plugin(({ addVariant }) =>
      addVariant("phx-submit-loading", [
        "&.phx-submit-loading",
        ".phx-submit-loading &",
      ])
    ),
    plugin(({ addVariant }) =>
      addVariant("phx-change-loading", [
        "&.phx-change-loading",
        ".phx-change-loading &",
      ])
    ),
  ],
};
