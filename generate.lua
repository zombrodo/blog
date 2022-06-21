#!/usr/bin/env luajit

local Renderer = require "src.renderer"
local TailwindWriter = require "src.writer.tailwind"
local template = "templates/tailwind"

Renderer.render(template, { writer = TailwindWriter, homepage = "/blog" })

local cmd = string.format(
  "npx tailwindcss -i ./%s/index.css -o ./build/index.css",
  template
)

os.execute(cmd)
