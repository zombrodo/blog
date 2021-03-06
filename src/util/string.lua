local StringUtils = {}

function StringUtils.kebabify(str)
  local result = str:lower():gsub('[%p%c]', ''):gsub(" ", "-")
  return result
end

function StringUtils.trim(str)
  local result = str:gsub("^%s*(.-)%s*$", "%1")
  return result
end

function StringUtils.startsWith(str, prefix)
  return string.sub(str, 1, string.len(prefix)) == prefix
end

function StringUtils.split(str, sep)
  local result = {}
  string.gsub(str, '[^'..sep..']+', function(m) table.insert(result, m) end)
  return result
end

return StringUtils
