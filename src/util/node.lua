local NodeUtils = {}

function NodeUtils.findNodeOfType(nodes, type)
  for i, elem in ipairs(nodes) do
    if elem.type == type then
      return elem
    end
  end
end

return NodeUtils
