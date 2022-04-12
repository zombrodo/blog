local Filesystem = {}

function Filesystem.loadFile(path)
  local file = io.open(path, "rb")
  local content = file:read("*all")
  file:close()
  return content
end

function Filesystem.writeFile(path, contents)
  print(path)
  local file = io.open(path, "w+")
  file:write(contents)
  file:close()
end

return Filesystem
