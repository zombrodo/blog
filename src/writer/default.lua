-- Default HTML writer. Spits out boring ol' HTML.

local DefaultWriter = {}

local function tag(tag, content)
  return string.format("<%s>%s</%s>", tag, content, tag)
end

-- =============================================================================
-- Default Writer
-- =============================================================================

function DefaultWriter.header(level, content)
  local t = string.format("h%s", level)
  return tag(t, content)
end

function DefaultWriter.paragraph(content)
  return tag("p", content)
end


function DefaultWriter.bold(content)
  return tag("strong", content)
end


function DefaultWriter.italic(content)
  return tag("em", content)
end


function DefaultWriter.code(content, _language)
  return tag("code", content)
end


function DefaultWriter.codeblock(content)
  local code = tag("code", content)
  return tag("pre", code)
end


function DefaultWriter.anchor(href, content)
  return string.format("<a href=\"%s\">%s</a>", href, content)
end


function DefaultWriter.image(href, content)
  return string.format("<img src=\"%s\">%s</img>", href, content)
end


function DefaultWriter.blockquote(content)
  return tag("blockquote", content)
end


function DefaultWriter.horizontalRule()
  return "<hr />"
end


function DefaultWriter.listItem(content)
  return tag("li", content)
end


function DefaultWriter.orderedList(content)
  return tag("ol", content)
end


function DefaultWriter.unorderedList(content)
  return tag("ul", content)
end

return DefaultWriter
