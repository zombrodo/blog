module.exports = {
  content: ["./templates/tailwind/**/*.mustache"],
  theme: {
    extend: {
      fontFamily: {
        "montserrat": ["Montserrat", "sans-serif"],
        "lora": ["Lora", "serif"],
        "mono": ["Source Code Pro", "monospace"]
      }
    },
  },
  plugins: [],
}
