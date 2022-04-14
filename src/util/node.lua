local NodeUtils = {}

-- TODO: traverse the tree, rather than roots
function NodeUtils.findFirstNodeOfType(nodes, type, attributes)
  for i, elem in ipairs(nodes) do
    if elem.type == type then
      local match = attributes == nil
      for k, v in pairs(attributes or {}) do
        if elem[k] == v then
          match = true
        else
          match = false
        end
      end

      if match then
        return elem, i
      end
    end
  end
end

return NodeUtils
