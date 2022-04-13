local lustache = require "lib.lustache"
local fs = require "src.util.fs"

local TailwindWriter = {}

local Templates = {
  header = fs.loadFile("templates/tailwind/elements/header.mustache"),
  paragraph = fs.loadFile("templates/tailwind/elements/paragraph.mustache"),
  bold = fs.loadFile("templates/tailwind/elements/bold.mustache"),
  italic = fs.loadFile("templates/tailwind/elements/italic.mustache"),
  code = fs.loadFile("templates/tailwind/elements/code.mustache"),
  codeblock = fs.loadFile("templates/tailwind/elements/codeblock.mustache"),
  anchor = fs.loadFile("templates/tailwind/elements/anchor.mustache"),
  image = fs.loadFile("templates/tailwind/elements/image.mustache"),
  blockquote = fs.loadFile("templates/tailwind/elements/blockquote.mustache"),
  horizontalRule = fs.loadFile("templates/tailwind/elements/horizontalRule.mustache"),
  listItem = fs.loadFile("templates/tailwind/elements/listItem.mustache"),
  orderedList = fs.loadFile("templates/tailwind/elements/orderedList.mustache"),
  unorderedList = fs.loadFile("templates/tailwind/elements/unorderedList.mustache"),
}

local function simple(template, content)
  return lustache:render(template, { content = content })
end

-- =============================================================================
-- Header
-- =============================================================================

local textSize = {
  "text-7xl",
  "text-3xl",
  "text-2xl",
  "text-xl",
  "text-lg",
  "text-lg",
}

local function resolveClassname(level)
  return textSize[level]
end


function TailwindWriter.header(level, content)
  return lustache:render(Templates.header, {
    level = level,
    content = content,
    classname = resolveClassname(level)
  })
end

-- =============================================================================
-- Paragraph, Bold, Italic, Inline Code
-- =============================================================================

function TailwindWriter.paragraph(content)
  return simple(Templates.paragraph, content)
end

function TailwindWriter.bold(content)
  return simple(Templates.bold, content)
end

function TailwindWriter.italic(content)
  return simple(Templates.italic, content)
end

function TailwindWriter.code(content)
  return simple(Templates.code, content)
end

-- =============================================================================
-- Codeblock
-- =============================================================================

function TailwindWriter.codeblock(content)
  return lustache:render(Templates.codeblock, { content = content })
end

-- =============================================================================
-- Anchors and Images
-- =============================================================================

function TailwindWriter.anchor(href, content)
  return lustache:render(Templates.anchor, {
    href = href,
    content = content,
  })
end

function TailwindWriter.image(href, content)
  return lustache:render(Templates.image, {
    href = href,
    content = content
  })
end

-- =============================================================================
-- Blockquote
-- =============================================================================

function TailwindWriter.blockquote(content)
  return lustache:render(Templates.blockquote, { content = content })
end

function TailwindWriter.horizontalRule()
  return lustache:render(Templates.horizontalRule, {})
end

-- =============================================================================
-- Lists
-- =============================================================================

function TailwindWriter.listItem(content)
  return simple(Templates.listItem, content)
end

function TailwindWriter.orderedList(content)
  return simple(Templates.orderedList, content)
end

function TailwindWriter.unorderedList(content)
  return simple(Templates.unorderedList, content)
end


return TailwindWriter
