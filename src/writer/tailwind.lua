local lustache = require "lib.lustache"
local node = require "src.util.node"
local fs = require "src.util.fs"
local stringUtils = require "src.util.string"

local TailwindWriter = {}

local Templates = {
  title = fs.loadFile("templates/tailwind/title.mustache"),
  series = fs.loadFile("templates/tailwind/series.mustache"),
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
  aside = fs.loadFile("templates/tailwind/elements/aside.mustache"),
}

local function simple(template, content)
  return lustache:render(template, { content = content })
end

-- =============================================================================
-- Title and other Custom Headers
-- =============================================================================

function TailwindWriter.title(node, context)
  return lustache:render(Templates.title, {
    title = node.title,
    day = node.day,
    month = node.month,
    year = node.year
  })
end

local months = { "January", "Feburary", "March", "April", "May", "June", "July",
  "August", "September", "October", "November", "December" }

-- Pretty naive, but probably easier than some icky trickery
local function addDaySuffix(day)
  if day == "1" or day == "21" or day == "31" then
    return day .. "st"
  end

  if day == "2" or day == "22" then
    return day .. "nd"
  end

  if day == "3" or day == "23" then
    return day .. "rd"
  end

  return day .. "th"
end

local function parseDate(str)
  local parts = stringUtils.split(str, "/")
  local day = parts[1]
  local month = parts[2]
  local year = parts[3]
  return addDaySuffix(day), months[tonumber(month)], year
end

local function buildDefaultTitleNode(documentTree, context)
  local h1, i = node.findFirstNodeOfType(documentTree, "header", { level = 1 })
  local day, month, year = parseDate(context.metadata.date)
  documentTree[i] = {
    type = "title",
    title = h1.content,
    day = day,
    month = month,
    year = year
  }
  context.addCustomNode("title")
  return documentTree
end

function TailwindWriter.series(node, context)
  return lustache:render(Templates.series, {
    series = node.series,
    part = node.part,
    day = node.day,
    month = node.month,
    year = node.year
  })
end

function TailwindWriter.prerender(documentTree, context)
  if context.metadata.format == "series" then
    local h1, i = node.findFirstNodeOfType(documentTree, "header", { level = 1 })
    local day, month, year = parseDate(context.metadata.date)
    documentTree[i] = {
      type = "series",
      series = context.metadata.series,
      part = h1.content,
      day = day,
      month = month,
      year = year
    }

    context.addCustomNode("series")
    return documentTree
  end

  return buildDefaultTitleNode(documentTree, context)
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

function TailwindWriter.codeblock(content, language)
  return lustache:render(Templates.codeblock, {
    content = content,
    language = (language or "plaintext")
  })
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

-- =============================================================================
-- Aside
-- =============================================================================

function TailwindWriter.aside(content)
  return simple(Templates.aside, content)
end

-- =============================================================================
-- Horizontal Rule
-- =============================================================================

function TailwindWriter.horizontalRule()
  return lustache:render(Templates.horizontalRule, {})
end

return TailwindWriter
