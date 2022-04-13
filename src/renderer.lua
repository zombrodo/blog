local lfs = require "lfs"
local lustache = require "lib.lustache"

local DefaultWriter = require "src.writer.default"
local nodeUtils = require "src.util.node"
local stringUtils = require "src.util.string"
local markdown = require "src.markdown"
local fs = require "src.util.fs"

local Renderer = {}

local function mergeWithDefault(writer)
  local result = {}
  for tag, func in pairs(DefaultWriter) do
    if writer[tag] then
      result[tag] = writer[tag]
    else
      result[tag] = func
    end
  end
  return result
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

function Renderer.head(template, metadata)
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

local function write(nodes, writer)
  local result = {}

  for i, node in ipairs(nodes) do
    if node.type == "header" then
      table.insert(result, writer.header(node.level, node.content))
    end

    if node.type == "paragraph" then
      table.insert(result, writer.paragraph(write(node.content, writer)))
    end

    if node.type == "text" then
      table.insert(result, node.content)
    end

    if node.type == "bold" then
      table.insert(result, writer.bold(node.content))
    end

    if node.type == "italic" then
      table.insert(result, writer.italic(node.content))
    end

    if node.type == "inlineCode" then
      table.insert(result, writer.code(node.content))
    end

    if node.type == "codeblock" then
      table.insert(result, writer.codeblock(node.content))
    end

    if node.type == "anchor" then
      table.insert(result, writer.anchor(node.href, node.content))
    end

    if node.type == "image" then
      table.insert(result, writer.image(node.href, node.content))
    end

    if node.type == "blockquote" then
      table.insert(result, writer.blockquote(write(node.content, writer)))
    end

    if node.type == "listItem" then
      table.insert(result, writer.listItem(write(node.content, writer)))
    end

    if node.type == "orderedList" then
      table.insert(result, writer.orderedList(write(node.content, writer)))
    end

    if node.type == "unorderedList" then
      table.insert(result, writer.unorderedList(write(node.content, writer)))
    end

    if node.type == "horizontalRule" then
      table.insert(result, writer.horizontalRule())
    end
  end

  return table.concat(result, "\n")
end

function Renderer.post(document, writer)
  return write(document, resolveWriter(writer))
end

-- =============================================================================
-- Posts
-- =============================================================================

function Renderer.posts(directory, template, writer)
  local allPosts = {}
  local postTemplate = fs.loadFile(string.format("%s/post.mustache", template))

  for file in lfs.dir(directory) do
    print(file)
    if file ~= "." and file ~= ".." and file ~= "static" then
      -- parse tree
      local fileContents = fs.loadFile(string.format("%s/%s", directory, file))
      local documentTree = markdown.parse(fileContents)
      -- retrieve meta
      local preamble = nodeUtils.findNodeOfType(documentTree, "preamble")
      local meta = preamble.meta
      -- render header
      local header = stringUtils.trim(Renderer.head(template, meta))
      -- render content
      local body = Renderer.post(documentTree, writer)
      -- render full post
      local output = lustache:render(postTemplate, {
        metadata = head,
        title = meta.title,
        content = body
      })


      local outputPath = string.format(
        "posts/%s.html",
        stringUtils.kebabify(meta.title)
      )

      fs.writeFile(string.format("build/%s", outputPath), output)
      table.insert(allPosts, {
        title = meta.title,
        path = outputPath
      })
    end
  end

  return allPosts
end

-- =============================================================================
-- Index
-- =============================================================================

function Renderer.index(posts, template, writer)
  local writer = mergeWithDefault(resolveWriter(writer))
  local indexTemplate = fs.loadFile(
    string.format("%s/index.mustache", template)
  )

  local postList = {}
  for i, post in ipairs(posts) do
    table.insert(
      postList,
      writer.listItem(writer.anchor(post.path, post.title))
    )
  end

  local output = lustache:render(indexTemplate, {
    posts = writer.unorderedList(table.concat(postList, "\n"))
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

function Renderer.render(template, writer)
  -- posts
  local posts = Renderer.posts("posts", template, writer)
  -- copy static
  Renderer.copyStatic("posts/static")
  -- index
  Renderer.index(posts, template, writer)
end

return Renderer
