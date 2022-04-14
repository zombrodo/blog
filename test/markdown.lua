local utils = require "test.util"
local markdown = require "src.markdown"

local lust = require 'lib.lust'
local describe, it, expect = lust.describe, lust.it, lust.expect

local function equalNode(a, b)
  if type(a) ~= type(b) then
    return false
  end

  if a.type ~= b.type then
    return false
  end

  if a.type == "header" then
    return a.level == b.level and a.content == b.content
  end

  if a.type == "preamble" then
    return utils.shallowEqual(a.meta, b.meta)
  end

  if a.type == "text"
    or a.type == "bold"
    or a.type == "italic"
    or a.type == "inlineCode" then
    return a.content == b.content
  end

  if a.type == "anchor" or a.type == "image" then
    return a.href == b.href and a.content == b.content
  end

  if a.type == "codeblock" then
    return a.language == b.language and a.content == b.content
  end

  if a.type == "horizontalRule" then
    -- they must both be the same type, and there is no content for one.
    return true
  end

  if a.type == "paragraph" then
    return utils.every(a.content, function(p, i)
      return equalNode(p, b.content[i])
    end)
  end

  if a.type == "unorderedList" or a.type == "orderedList" then
    return utils.every(a.content, function(li, i)
      return equalNode(li, b.content[i])
    end)
  end

  if a.type == "listItem" then
    return utils.every(a.content, function(c, i)
      return equalNode(c, b.content[i])
    end)
  end

  if a.type == "blockquote" then
    return utils.every(a.content, function(bq, i)
      return equalNode(bq, b.content[i])
    end)
  end

  if a.type == "aside" then
    return utils.every(a.content, function(as, i)
      return equalNode(as, b.content[i])
    end)
  end

  return false
end

-- =============================================================================

local function nodeFormat(node)
  if node and node.type then
    return string.format("[%s node: %s]", node.type, node)
  end

  return string.format("[Node %s]", node)
end

lust.paths.equalNode = {
  test = function(a, b)
    return equalNode(a, b),
      string.format("expected %s to node equal %s.", nodeFormat(a), nodeFormat(b)),
      string.format("expected %s to not node equal %s.", nodeFormat(a), nodeFormat(b))
  end
}

table.insert(lust.paths.to, "equalNode")

-- =============================================================================

describe("header", function()
  it("should parse the correct node", function()
    expect(utils.first(markdown.parse("# h1"))).to.equalNode(
      { type = "header", level = 1, content = "h1"}
    )
    expect(utils.first(markdown.parse("## h2"))).to.equalNode(
      { type = "header", level = 2, content = "h2"}
    )
    expect(utils.first(markdown.parse("### h3"))).to.equalNode(
      { type = "header", level = 3, content = "h3"}
    )
    expect(utils.first(markdown.parse("#### h4"))).to.equalNode(
      { type = "header", level = 4, content = "h4"}
    )
    expect(utils.first(markdown.parse("##### h5"))).to.equalNode(
      { type = "header", level = 5, content = "h5"}
    )
    expect(utils.first(markdown.parse("###### h6"))).to.equalNode(
      { type = "header", level = 6, content = "h6"}
    )
  end)
end)

-- =============================================================================


local preambleInput =
[[%%
  title=This is a title
  tags=these,are,tags
  %%]]

describe("preamble", function()
  it("should parse the correct node", function()
    expect(utils.first(markdown.parse(preambleInput))).to.equalNode(
      { type = "preamble", meta = { title = "This is a title", tags = "these,are,tags" }}
    )
  end)
end)

-- =============================================================================

local paragraph =
[[
This is a paragraph,
and only a single new line will not create a new node.

... But two would.
]]

describe("paragraph", function()
  it("should parse the correct node", function()
    expect(utils.first(markdown.parse(paragraph))).to.equalNode(
      {
        type = "paragraph",
        content = {
          {
            type = "text",
            content = [[This is a paragraph,and only a single new line will not create a new node.]]
          }
        }
    })
  end)
end)

-- =============================================================================

local bold = "This line contains some **bold** text"

describe("bold", function()
  it("should parse the correct node", function()
    local p = utils.first(markdown.parse(bold)).content
    local b = utils.second(p)
    expect(b).to.equalNode({ type = "bold", content = "bold" })
  end)
end)

-- =============================================================================

local italic = "This line contains some _italic_ text"

describe("italic", function()
  it("should parse the correct node", function()
    local p = utils.first(markdown.parse(italic)).content
    local i = utils.second(p)
    expect(i).to.equalNode({ type = "italic", content = "italic" })
  end)
end)

-- =============================================================================

local inlineCode = "This line contains some `inline code` text"

describe("inline code", function()
  it("should parse the correct node", function()
    local p = utils.first(markdown.parse(inlineCode)).content
    local ic = utils.second(p)
    expect(ic).to.equalNode({ type = "inlineCode", content = "inline code" })
  end)
end)

-- =============================================================================

local anchor = "This line contains a [link](http://example.com) text"

describe("anchor", function()
  it("should parse the correct node", function()
    local p = utils.first(markdown.parse(anchor)).content
    local a = utils.second(p)
    expect(a).to.equalNode({
      type = "anchor",
      content = "link",
      href="http://example.com"
    })
  end)
end)

-- =============================================================================

local image = "![image](http://example.com/example.png)"

describe("image", function()
  it("should parse the correct node", function()
    expect(utils.first(markdown.parse(image))).to.equalNode({
      type = "image",
      content = "image",
      href="http://example.com/example.png"
    })
  end)
end)

-- =============================================================================

local codeblock = [[```html
<p>this is a code block</p>
```]]

describe("codeblock", function()
  it("should parse the correct node", function()
    expect(utils.first(markdown.parse(codeblock))).to.equalNode({
      type = "codeblock",
      content = "<p>this is a code block</p>",
      language = "html"
    })
  end)
end)

-- =============================================================================

local horizontalRule= "---"

describe("horizontal rule", function()
  it("should parse the correct node", function()
    expect(utils.first(markdown.parse(horizontalRule))).to.equalNode({
      type = "horizontalRule"
    })
  end)
end)

-- =============================================================================

local ul = [[* item one
* item two
* item three]]

describe("unordered list", function()
  it("should parse the correct node", function()
    expect(utils.first(markdown.parse(ul))).to.equalNode({
      type = "unorderedList",
      content = {
        {
          type = "listItem",
          content = {
            {
              type = "text",
              content = "item one"
            },
          },
        },
        {
          type = "listItem",
          content = {
            {
              type = "text",
              content = "item two"
            },
          },
        },
        {
          type = "listItem",
          content = {
            {
              type = "text",
              content = "item three"
            },
          },
        }
      }
    })
  end)
end)

-- =============================================================================

local ol = [[1. item one
2. item two
3. item three]]

describe("ordered list", function()
  it("should parse the correct node", function()
    expect(utils.first(markdown.parse(ol))).to.equalNode({
      type = "orderedList",
      content = {
        {
          type = "listItem",
          content = {
            {
              type = "text",
              content = "item one"
            },
          },
        },
        {
          type = "listItem",
          content = {
            {
              type = "text",
              content = "item two"
            },
          },
        },
        {
          type = "listItem",
          content = {
            {
              type = "text",
              content = "item three"
            },
          },
        }
      }
    })
  end)
end)

-- =============================================================================

local blockquote =
[[
>this is a blockquote
]]

describe("blockquote", function()
  it("should parse the correct node", function()
    expect(utils.first(markdown.parse(blockquote))).to.equalNode(
      {
        type = "blockquote",
        content = {
          {
            type = "text",
            content = "this is a blockquote"
          }
        }
    })
  end)
end)

-- =============================================================================

local aside = "$>This is an aside, generally some cheeky note I leave."

describe("aside", function()
  it("should parse the correct node", function()
    expect(utils.first(markdown.parse(aside))).to.equalNode({
      type = "aside",
      content = {
        {
          type = "text",
          content = "This is an aside, generally some cheeky note I leave."
        }
      }
    })
  end)
end)
