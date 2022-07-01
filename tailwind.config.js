module.exports = {
  content: ["./templates/tailwind/**/*.{mustache, lua}"],
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
