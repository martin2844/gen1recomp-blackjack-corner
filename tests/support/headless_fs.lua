local FsIo = require("tests.fs_io")

local HeadlessFs = {}

local DERIVED_ROOT = "save/mod-derived/"

local function isDerived(path)
  return type(path) == "string"
    and path:sub(1, #DERIVED_ROOT) == DERIVED_ROOT
end

local function basename(path)
  return tostring(path):gsub("/+$", ""):match("[^/]+$")
end

function HeadlessFs.new(paths, root)
  local inner = FsIo.new(root or ".")
  local derived = {}
  local fs = { root = inner.root }
  local aliases = {}
  for _, path in ipairs(paths or {}) do aliases[basename(path)] = path end

  local function map(path)
    if path == nil then return path end
    for name, real in pairs(aliases) do
      local prefix = "mods/" .. name
      if path == prefix then return real end
      if path:sub(1, #prefix + 1) == prefix .. "/" then
        return real .. path:sub(#prefix + 1)
      end
    end
    return path
  end

  function fs.read(path)
    if isDerived(path) and derived[path] ~= nil then return derived[path] end
    return inner.read(map(path))
  end

  function fs.write(path, body)
    if isDerived(path) then
      derived[path] = body
      return true
    end
    return inner.write(map(path), body)
  end

  function fs.load(path)
    return inner.load(map(path))
  end

  function fs.getInfo(path)
    if isDerived(path) then
      if derived[path] ~= nil then return { type = "file" } end
      local prefix = path:gsub("/+$", "") .. "/"
      for key in pairs(derived) do
        if key:sub(1, #prefix) == prefix then
          return { type = "directory" }
        end
      end
    end
    if path == "mods" then return { type = "directory" } end
    return inner.getInfo(map(path))
  end

  function fs.createDirectory(path)
    if isDerived(path) then return true end
    return inner.createDirectory and inner.createDirectory(map(path)) or false
  end

  function fs.getDirectoryItems(path)
    if path == "mods" then
      local names = {}
      for name in pairs(aliases) do names[#names + 1] = name end
      table.sort(names)
      return names
    end
    return inner.getDirectoryItems(map(path))
  end

  return fs
end

return HeadlessFs
