local StringUtils = {}

function StringUtils.kebabify(str)
  local result = str:lower():gsub('[%p%c]', ''):gsub(" ", "-")
  return result
end

function StringUtils.trim(str)
  local result = str:gsub("^%s*(.-)%s*$", "%1")
  return result
end

return StringUtils
