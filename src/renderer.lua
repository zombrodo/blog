local lfs = require "lfs"
local lustache = require "lib.lustache"

local DefaultWriter = require "src.writer.default"
local nodeUtils = require "src.util.node"
local stringUtils = require "src.util.string"
local markdown = require "src.markdown"
local fs = require "src.util.fs"

local Renderer = {}

local function mergeWithDefault(writer)
  for tag, func in pairs(DefaultWriter) do
    if not writer[tag] then
      writer[tag] = func
    end
  end
  return writer
end

local function resolveWriter(writer)
  if not writer then
    writer = {}
  end

  return mergeWithDefault(writer)
end

-- =============================================================================
-- Header
-- =============================================================================

local function meta(name, content)
  return string.format("<meta name=\"%s\" content=\"%s\">", name, content)
end

function Renderer.head(template, context)
  local metadata = context.metadata
  local headTemplate = fs.loadFile(string.format("%s/head.mustache", template))
  local result = {}

  for name, content in pairs(metadata) do
    table.insert(result, meta(name, content))
  end


  local output = lustache:render(headTemplate, {
    metadata = table.concat(result, "\n"),
  })

  return stringUtils.trim(output)
end

-- =============================================================================
-- Post
-- =============================================================================

local function contains(tbl, item)
  for i, elem in ipairs(tbl) do
    if elem == item then
      return true
    end
  end
  return false
end

local function write(nodes, writer, context)
  local result = {}

  for i, node in ipairs(nodes) do
    if node.type == "header" then
      table.insert(result, writer.header(node.level, node.content, context))
    end

    if node.type == "paragraph" then
      table.insert(
        result, writer.paragraph(write(node.content, writer, context))
      )
    end

    if node.type == "text" then
      table.insert(result, node.content)
    end

    if node.type == "bold" then
      table.insert(result, writer.bold(node.content, context))
    end

    if node.type == "italic" then
      table.insert(result, writer.italic(node.content, context))
    end

    if node.type == "inlineCode" then
      table.insert(result, writer.code(node.content, context))
    end

    if node.type == "codeblock" then
      table.insert(
        result, writer.codeblock(node.content, node.language, context)
      )
    end

    if node.type == "anchor" then
      table.insert(result, writer.anchor(node.href, node.content, context))
    end

    if node.type == "image" then
      table.insert(result, writer.image(node.href, node.content, context))
    end

    if node.type == "blockquote" then
      table.insert(
        result,
        writer.blockquote(
          node.insert,
          write(node.content, writer, context),
          context)
        )
    end

    if node.type == "listItem" then
      table.insert(
        result, writer.listItem(write(node.content, writer, context), context)
      )
    end

    if node.type == "orderedList" then
      table.insert(
        result,
        writer.orderedList(write(node.content, writer, context), context)
      )
    end

    if node.type == "unorderedList" then
      table.insert(
        result,
        writer.unorderedList(write(node.content, writer, context), context)
      )
    end

    if node.type == "horizontalRule" then
      table.insert(result, writer.horizontalRule(context))
    end

    if node.type == "aside" then
      table.insert(
        result, writer.aside(write(node.content, writer, context), context)
      )
    end

    if contains(context._customNodes, node.type) and writer[node.type] then
      table.insert(result, writer[node.type](node, context))
    end
  end

  return table.concat(result, "\n")
end

function Renderer.post(document, writer, context)
  writer = resolveWriter(writer)
  title, document = writer.prerender(document, context)
  return write({ title }, writer, context), write(document, writer, context)
end

-- =============================================================================
-- Posts
-- =============================================================================

function Renderer.posts(directory, template, config)
  local allPosts = {}
  local postTemplate = fs.loadFile(string.format("%s/post.mustache", template))
  local homepage = config.homepage or ""

  for file in lfs.dir(directory) do
    if file ~= "." and file ~= ".." and file ~= "static" then
      -- parse tree
      local fileContents = fs.loadFile(string.format("%s/%s", directory, file))
      local documentTree = markdown.parse(fileContents)
      -- retrieve meta
      local preamble = nodeUtils.findFirstNodeOfType(documentTree, "preamble")
      local metadata = preamble.meta
      -- build context
      local context = {}
      context.metadata = metadata
      context._customNodes = {}
      context.addCustomNode = function(node)
        table.insert(context._customNodes, node)
      end
      -- render header
      local header = stringUtils.trim(Renderer.head(template, context))
      -- render content
      local title, body = Renderer.post(documentTree, config.writer, context)
      -- render full post
      local output = lustache:render(postTemplate, {
        metadata = head,
        pageTitle = metadata.title,
        homepage = homepage,
        title = title,
        content = body
      })

      local kebabedTitle = stringUtils.kebabify(metadata.title)
      local urlPath = string.format("posts/%s", kebabedTitle)
      local outputDirectory = string.format("build/%s", urlPath)

      -- TODO: This'll fail silently, but we should return and handle an error
      -- more gracefully
      lfs.mkdir(outputDirectory)

      fs.writeFile(string.format("%s/index.html", outputDirectory), output)

      table.insert(allPosts, {
        metadata = metadata,
        title = metadata.title,
        path = string.format("%s/%s", homepage, urlPath)
      })
    end
  end

  return allPosts
end

-- =============================================================================
-- Index
-- =============================================================================

function Renderer.index(posts, template, config)
  local writer = mergeWithDefault(resolveWriter(config.writer))
  local indexTemplate = fs.loadFile(
    string.format("%s/index.mustache", template)
  )

  local output = lustache:render(indexTemplate, {
    posts = writer.postsListing(posts)
  })

  fs.writeFile("build/index.html", output)
end

-- =============================================================================
-- Copy
-- =============================================================================

function Renderer.copyStatic(path)
  for file in lfs.dir(path) do
    if file ~= "." and file ~= ".." then
      fs.writeFile(
        string.format("build/posts/static/%s", file),
        fs.loadFile(string.format("%s/%s", path, file))
      )
    end
  end
end

-- =============================================================================
-- Entrypoint
-- =============================================================================

function Renderer.render(template, config)
  -- posts
  local posts = Renderer.posts("posts", template, config)
  -- copy static
  Renderer.copyStatic("posts/static")
  -- index
  Renderer.index(posts, template, config)
end

return Renderer
