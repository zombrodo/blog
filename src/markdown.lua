-- =============================================================================
-- Markdown v0.1.0
-- This is a custom markdown parser built specifically for my use case. It was
-- mainly used an excuse to learn LPeg, therefore it may look pretty copy and
-- paste heavy, and contain a (fair) few inconsistencies.
-- Only supports a subsection of the Markdown standard (ie. no nested lists)
-- =============================================================================

local lpeg = require "lpeg"

local Markdown = {}

-- =============================================================================
-- Utils
-- =============================================================================

local function trim(str)
  local result = str:gsub("^%s*(.-)%s*$", "%1")
  return result
end

local function split (str, sep)
  if sep == nil then
     sep = "%s"
  end
  local t={}
  for str in string.gmatch(str, "([^"..sep.."]+)") do
     table.insert(t, str)
  end
  return t
end

local function basicNode(type, content)
  return {
    type = type,
    content = content
  }
end

-- =============================================================================
-- Nodes
-- =============================================================================

local function preambleNode(_symbol, position, contents)
  local data = {}
  -- TODO: Would have been nice to capture this with an LPeg rule, but for the
  -- sake of progress
  local rows = split(contents, "\n")
  for i, elem in ipairs(rows) do
    local info = split(elem, "=")
    data[trim(info[1])] = info[2]
  end

  return position, {
    type = "preamble",
    meta = data
  }
end

local function headerNode(level, content)
  return {
    type = "header",
    level = level,
    content = content
  }
end

local function textNode(content)
  return basicNode("text", content)
end

local function flattenTextNodes(nodes)
  local nodeContent = {}
  local currentTextBlock = {}
  for i, elem in ipairs(nodes) do
      if elem.type == "text" then
        -- newlines in paragraph/blockquotes are just sugar in the editor, and
        -- should be replaced with spaces.
        if elem.content == "\n" then
          table.insert(currentTextBlock, " ")
        else
          table.insert(currentTextBlock, elem.content)
        end
      else
        if #currentTextBlock > 0 then
          table.insert(nodeContent, textNode(table.concat(currentTextBlock)))
          currentTextBlock = {}
        end
        table.insert(nodeContent, elem)
      end
  end

  if #currentTextBlock > 0 then
    table.insert(nodeContent, textNode(trim(table.concat(currentTextBlock))))
  end

  return nodeContent
end

local function paragraphNode(content)
  return basicNode("paragraph", flattenTextNodes(content))
end

local function anchorNode(_symbol, position, content, href)
  return position, {
    type = "anchor",
    content = content,
    href = href
  }
end

local function boldNode(_symbol, position, content)
  return position, basicNode("bold", content)
end

local function italicNode(_symbol, position, content)
  return position, basicNode("italic", content)
end

local function inlineCodeNode(_symbol, position, content)
  return position, basicNode("inlineCode", content)
end

local function imageNode(_symbol, position, content, href)
  return position, {
    type = "image",
    content = content,
    href = href,
  }
end

local function codeblockNode(_symbol, position, lang, content)
  -- Omit if no lang found
  if lang == "" then
    lang = nil
  end

  return position, {
    type = "codeblock",
    language = lang,
    content = trim(content)
  }
end

local function horizontalRuleNode()
  return {
    type = "horizontalRule"
  }
end

local function listItemNode(_symbol, position, content)
  return position, basicNode("listItem", flattenTextNodes(content))
end

local function unorderedListNode(_symbol, position, content)
  return position, basicNode("unorderedList", content)
end

local function orderedListNode(_symbol, position, content)
  return position, basicNode("orderedList", content)
end

local function blockquoteNode(_symbol, position, insert, content)
  -- If `insert` is a table, then there is no insert - just a standard blockquote
  if type(insert) == "table" then
    return position, {
      type = "blockquote",
      insert = false,
      content = flattenTextNodes(insert)
    }
  end

  return position, {
    type = "blockquote",
    insert = insert,
    content = flattenTextNodes(content)
  }
end

local function asideNode(_symbol, position, content)
  return position, basicNode("aside", flattenTextNodes(content))
end

-- =============================================================================
-- Patterns
-- =============================================================================

-- Preamble

local function preamblePattern()
  local preamble = lpeg.P("%%") * lpeg.C((1 - lpeg.P("%%")) ^ 0) * lpeg.P("%%")
  return lpeg.Cmt(preamble, preambleNode)
end

-- Header

local function headerPattern(level)
  local prefix = string.rep("#", level)
  local capture = function(str)
    return headerNode(level, trim(str))
  end

  return lpeg.P(prefix) * (((1 - lpeg.V("newline")) ^ 0) / capture) * (lpeg.V("newline") + -1)
end

local function headersPattern()
  return headerPattern(6) + headerPattern(5) + headerPattern(4)
    + headerPattern(3) + headerPattern(2) + headerPattern(1)
end

-- Line

local function inlinePattern(symbol)
  return lpeg.P(symbol)  * lpeg.C((1 - lpeg.P(symbol)) ^ 1) * lpeg.P(symbol)
end

local function linePattern()
  local anchorPattern = lpeg.P("[") * lpeg.C((1 - lpeg.P("]")) ^ 0)
    * lpeg.P("]") * lpeg.P("(") * lpeg.C((1 - lpeg.P(")")) ^ 0) * lpeg.P(")")

  local anchor = lpeg.Cmt(anchorPattern, anchorNode)
  local bold = lpeg.Cmt(inlinePattern("**"), boldNode)
  local italic = lpeg.Cmt(inlinePattern("_"), italicNode)
  local inlineCode = lpeg.Cmt(inlinePattern("`"), inlineCodeNode)
  local plainText = (1 - lpeg.V("newline")) / textNode

  return (anchor + bold + italic + inlineCode + plainText) ^ 1
end

-- Paragraph

local function paragraphPattern()
  return lpeg.Ct(lpeg.V("lines") * lpeg.V("newline")) / paragraphNode
end

-- Image

local function imagePattern()
  -- TODO: Shares most of this rule with anchor, but anchor is not known.
  -- consider merging?

  local imagePattern = lpeg.P("!") * lpeg.P("[") * lpeg.C((1 - lpeg.P("]")) ^ 0) * lpeg.P("]")
  * lpeg.P("(") * lpeg.C((1 - lpeg.P(")")) ^ 0) * lpeg.P(")")

  return lpeg.Cmt(imagePattern, imageNode)
end

-- Codeblock

local function codeblockPattern()
  local rule = lpeg.P("```")
  * lpeg.C((1 - lpeg.V("newline")) ^ 0)
  * lpeg.V("newline")
  * lpeg.C((1 - lpeg.P("```")) ^ 0)
  * lpeg.P("```")

  return lpeg.Cmt(rule, codeblockNode)
end

-- Horizontal Rule

local function horizontalRulePattern()
  return (lpeg.P("---") * lpeg.V("newline")) ^ 1 / horizontalRuleNode
end

-- Unordered List and List Item

local function unorderedListItemPattern()
  local rule = lpeg.P("*")
    * lpeg.V("optionalWhitespace")
    * lpeg.Ct(lpeg.V("line"))
    * lpeg.V("newline")
  return lpeg.Cmt(rule, listItemNode)
end

local function unorderedListPattern()
  local rule = lpeg.Ct(lpeg.V("unorderedListItem") ^ 1)
  return lpeg.Cmt(rule, unorderedListNode)
end

-- Ordered List and List Item

local function orderedListItemPattern()
  local rule = lpeg.R("09") ^ 1
    * lpeg.P(".")
    * lpeg.V("optionalWhitespace")
    * lpeg.Ct(lpeg.V("line"))
    * lpeg.V("newline")
  return lpeg.Cmt(rule, listItemNode)
end

local function orderedListPattern()
  local rule = lpeg.Ct(lpeg.V("orderedListItem") ^ 1)
  return lpeg.Cmt(rule, orderedListNode)
end

-- Blockquote

local function blockquotePattern()
  local insert = lpeg.V("optionalWhitespace")
    * lpeg.P("[!")
    * lpeg.C((1 - lpeg.P("]")) ^ 0)
    * lpeg.P("]")
    * lpeg.V("optionalWhitespace")

  local rule =  lpeg.P(">") * insert ^ 0 * lpeg.Ct(lpeg.V("lines") * lpeg.V("newline"))

  return lpeg.Cmt(rule, blockquoteNode)
end

-- Asides

local function asidePattern()
  local rule = lpeg.P("=>") * lpeg.Ct(lpeg.V("line")) * lpeg.V("newline")
  return lpeg.Cmt(rule, asideNode)
end

-- =============================================================================
-- Entrypoint
-- =============================================================================

local rules = {
  "markdown",
  newline = lpeg.P("\n") + -1,
  optionalWhitespace = lpeg.S("\t ") ^ 0,
  preamble = preamblePattern(),
  header = headersPattern(),
  line = linePattern(),
  lines = (lpeg.V("line") * (lpeg.V("newline") / textNode)) ^ 1,
  paragraph = paragraphPattern(),
  image = imagePattern(),
  codeblock = codeblockPattern(),
  horizontalRule = horizontalRulePattern(),
  unorderedListItem = unorderedListItemPattern(),
  unorderedList = unorderedListPattern(),
  orderedListItem = orderedListItemPattern(),
  orderedList = orderedListPattern(),
  blockquote = blockquotePattern(),
  aside = asidePattern(),
  lists = lpeg.V("unorderedList") + lpeg.V("orderedList"),
  content = lpeg.V("aside") + lpeg.V("lists") + lpeg.V("horizontalRule")
    + lpeg.V("codeblock") + lpeg.V("image") + lpeg.V("blockquote")
    + lpeg.V("paragraph"),
  markdown = (lpeg.V("preamble") ^ 0) * (lpeg.S("\n") ^ 1 + lpeg.V("header") + lpeg.V("content")) ^ 0 * lpeg.V("newline")
}

function Markdown.parse(input)
  local markdown = lpeg.Ct(rules)
  return markdown:match(input)
end

return Markdown
