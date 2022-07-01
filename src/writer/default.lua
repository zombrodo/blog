-- Default HTML writer. Spits out boring ol' HTML.

local DefaultWriter = {}

local function tag(tag, content)
  return string.format("<%s>%s</%s>", tag, content, tag)
end

function DefaultWriter.postsListing(posts)

  local postList = {}
  for i, post in ipairs(posts) do
    table.insert(
      postList,
      DefaultWriter.listItem(DefaultWriter.anchor(post.path, post.title))
    )
  end

  return DefaultWriter.unorderedList(table.concat(postList, "\n"))
end

-- =============================================================================
-- Default Writer
-- =============================================================================

function DefaultWriter.header(level, content, _context)
  local t = string.format("h%s", level)
  return tag(t, content)
end

function DefaultWriter.paragraph(content, _context)
  return tag("p", content)
end


function DefaultWriter.bold(content, _context)
  return tag("strong", content)
end


function DefaultWriter.italic(content, _context)
  return tag("em", content)
end


function DefaultWriter.code(content, _language, _context)
  return tag("code", content)
end


function DefaultWriter.codeblock(content, _context)
  local code = tag("code", content)
  return tag("pre", code)
end


function DefaultWriter.anchor(href, content, _context)
  return string.format("<a href=\"%s\">%s</a>", href, content)
end


function DefaultWriter.image(href, content, _context)
  return string.format("<img src=\"%s\">%s</img>", href, content)
end


function DefaultWriter.blockquote(_insertType, content, _context)
  -- Ignore inserts, just render a plain Blockquote
  return tag("blockquote", content)
end


function DefaultWriter.horizontalRule(_context)
  return "<hr />"
end


function DefaultWriter.listItem(content, _context)
  return tag("li", content)
end


function DefaultWriter.orderedList(content, _context)
  return tag("ol", content)
end


function DefaultWriter.unorderedList(content, _context)
  return tag("ul", content)
end

function DefaultWriter.aside(content, _context)
  return tag("aside", content)
end

-- =============================================================================
-- Callbacks
-- =============================================================================

function DefaultWriter.prerender(documentTree, _context)
  return documentTree
end

return DefaultWriter
