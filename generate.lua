#!/usr/bin/env luajit

local Renderer = require "src.renderer"
local template = "templates/tailwind"

Renderer.render(template)
