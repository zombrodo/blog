local lustache = require "lib.lustache"
local date = require "lib.date"
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
  infoInsert = fs.loadFile("templates/tailwind/elements/insert/info.mustache"),
  warningInsert = fs.loadFile("templates/tailwind/elements/insert/warn.mustache")
}

local function simple(template, content)
  return lustache:render(template, { content = content })
end

-- =============================================================================
-- Date Helpers
-- =============================================================================

local months = { "January", "Feburary", "March", "April", "May", "June", "July",
  "August", "September", "October", "November", "December" }

-- Pretty naive, but probably easier than some icky trickery
local function addDaySuffix(day)
  if day == 1 or day == 21 or day == 31 then
    return day .. "st"
  end

  if day == 2 or day == 22 then
    return day .. "nd"
  end

  if day == 3 or day == 23 then
    return day .. "rd"
  end

  return day .. "th"
end

local function parseDate(str)
  local parts = stringUtils.split(str, "/")
  local day = parts[1]
  local month = parts[2]
  local year = parts[3]

  return date(tonumber(year), tonumber(month), tonumber(day))
end

local function getDateString(dateObj)
  return string.format(
    "%s %s, %d",
    addDaySuffix(dateObj:getday()),
    months[dateObj:getmonth()],
    dateObj:getyear()
  )
end

local function dateSort(a, b)
  return a.metadata.date < b.metadata.date
end

-- =============================================================================
-- Title and other Custom Headers
-- =============================================================================

function TailwindWriter.title(node, context)
  return lustache:render(Templates.title, {
    title = node.title,
    dateString = node.dateString
  })
end

local function buildDefaultTitleNode(documentTree, context)
  local h1, i = node.findFirstNodeOfType(documentTree, "header", { level = 1 })

  local titleNode = {
    type = "title",
    title=h1.content,
    dateString = getDateString(context.metadata.date)
  }

  table.remove(documentTree, i)

  context.addCustomNode("title")
  return titleNode, documentTree
end

function TailwindWriter.series(node, context)
  return lustache:render(Templates.series, {
    series = node.series,
    part = node.part,
    dateString = node.dateString
  })
end

function TailwindWriter.prerender(documentTree, context)
  -- TODO: This is a little black magic-y. We should either standardise that
  -- posts _must_ have dates, or at least a better API for this.
  context.metadata.date = parseDate(context.metadata.date)

  if context.metadata.format == "series" then
    local h1, i = node.findFirstNodeOfType(documentTree, "header", { level = 1 })
    local titleNode = {
      type = "series",
      series = context.metadata.series,
      part = h1.content,
      dateString = getDateString(context.metadata.date)
    }
    table.remove(documentTree, i)
    context.addCustomNode("series")

    return titleNode, documentTree
  end

  local titleNode, documentTree = buildDefaultTitleNode(documentTree, context)
  return titleNode, documentTree
end

-- =============================================================================
-- Index Page
-- =============================================================================

local function smallDate(str)
  return string.format("<span class=\"text-sm italic\">%s</span>", str)
end

local function renderPost(post)
  return TailwindWriter.listItem(
    string.format(
      "%s - %s",
      TailwindWriter.anchor(post.path, post.title),
      smallDate(getDateString(post.metadata.date)))
  )
end

local function renderList(items)
  return TailwindWriter.unorderedList(items)
end

local function renderSeries(title)
  return TailwindWriter.header(3, "Series: " .. title)
end

local function mapItems(fn, coll)
  local result = {}
  for i, elem in ipairs(coll) do
    table.insert(result, fn(elem))
  end

  return table.concat(result, "\n")
end

function TailwindWriter.postsListing(posts)
  local series = {}
  local allOther = {}

  for i, post in ipairs(posts) do
    if post.metadata.series then
      local s = post.metadata.series
      if not series[s] then
        series[s] = {}
      end
      table.insert(series[s], post)
    else
      table.insert(allOther, post)
    end
  end

  local result = {}

  table.insert(result, renderList(mapItems(renderPost, allOther)))

  for series, posts in pairs(series) do
    table.insert(result, renderSeries(series))
    table.sort(posts, dateSort)
    table.insert(result, renderList(mapItems(renderPost, posts)))
  end

  return table.concat(result, "\n")
end

-- =============================================================================
-- Header
-- =============================================================================

local textSize = {
  "text-4xl sm:text-8xl",
  "text-2xl sm:text-5xl",
  "text-xl sm:text-3xl",
  "text-lg sm:text-xl",
  "text-md sm:text-lg",
  "text-md sm:text-lg",
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

function TailwindWriter.insert(insertType, content)
  if insertType == "WARNING" then
    return lustache:render(Templates.warningInsert, { content = content })
  end
  return lustache:render(Templates.infoInsert, { content = content })
end

function TailwindWriter.blockquote(insertType, content)
  if insertType then
    return TailwindWriter.insert(insertType, content)
  end

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
