#!/usr/bin/env luajit

local Renderer = require "src.renderer"
local TailwindWriter = require "src.writer.tailwind"
local template = "templates/tailwind"

Renderer.render(template, TailwindWriter)
