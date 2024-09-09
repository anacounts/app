// See the Tailwind configuration guide for advanced usage
// https://tailwindcss.com/docs/configuration

const plugin = require("tailwindcss/plugin");
const defaultTheme = require("tailwindcss/defaultTheme");

module.exports = {
  content: [
    "./js/**/*.js",
    "../lib/*_web.ex",
    "../lib/*_web/**/*.*ex",
    // Storybook stories
    "../storybook/**/*.story.exs",
  ],
  theme: {
    borderRadius: {
      component: "0.5rem",
      container: "1rem",
      full: "9999px",

      // TODO(v2,end) remove default border radius values
      DEFAULT: "0.25rem",
      md: "0.375rem",
      lg: "0.5rem",
      "3xl": "1.5rem",
    },
    extend: {
      colors: {
        // Theme colors
        theme: {
          50: "#fff0ee",
          100: "#ffcab9",
          200: "#ffa78b",
          300: "#ff845d",
          400: "#ff602e",
          500: "#ff3d00",
          600: "#d13200",
          700: "#a22700",
          800: "#741c00",
          900: "#461100",
          950: "#170600",
          // TODO deprecated shades, to be removed
          darker: "#cc3000",
          DEFAULT: "#ff3d00",
          lighter: "#ff501a",
          contrast: "#ffffff",
        },

        // TODO(v2,end) remove all custom colors but `theme`
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
      spacing: {
        xs: "1.5rem",
        sm: "2rem",
        md: "2.5rem",
      },
      width: {
        prose: "65ch",
      },
      fontFamily: {
        sans: ["Lato", ...defaultTheme.fontFamily.sans],
      },
      animation: {
        "fade-in": "fade-in 150ms ease-in forwards",
        "backdrop-fade-in": "backdrop-fade-in 150ms ease-in forwards",
        "slide-in": "slide-in 150ms ease forwards",
      },
      keyframes: {
        "fade-in": {
          from: { opacity: "0" },
          to: { opacity: "1" },
        },
        "backdrop-fade-in": {
          from: { "backgroud-color": "transparent" },
          to: { "background-color": "rgba(0, 0, 0, 0.6)" },
        },
        "slide-in": {
          from: { translate: "0 1rem" },
          to: { translate: "0 0" },
        },
      },
    },
  },
  plugins: [
    // TODO(v2,end) remove typography plugin
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

  // Instruction required for `:phoenix_storybook`
  important: ".app-web",
};
