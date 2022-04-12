local utils = {}

function utils.isString(v)
  return type(v) == "string"
end

function utils.isTable()
  return type(v) == "table"
end

function utils.printTable(tbl)
  for k, elem in pairs(tbl) do
    print(k, elem)
  end
end

function utils.shallowEqual(a, b)
  for k, v in pairs(a) do
    if v ~= b[k] then
      return false
    end
  end

  return true
end

function utils.first(tbl)
  return tbl[1]
end

function utils.second(tbl)
  return tbl[2]
end

function utils.every(coll, fn)
  for i, elem in ipairs(coll) do
    if not fn(elem, i) then
      return false
    end
  end
  return true
end

return utils
