module.exports = {
  content: ["./templates/tailwind/**/*.{mustache, md}"],
  theme: {
    extend: {
      fontFamily: {
        "aktiv": ["aktiv-grotesk", "sans-serif"],
        "lora": ["Lora", "serif"],
        "mono": ["Source Code Pro", "monospace"]
      },
      fontWeight: {
        "extra-bold": 800,
      }
    },
  },
}
