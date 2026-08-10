local World = {}

function World.cloneList(rows)
  local out = {}
  for index, original in ipairs(rows or {}) do
    if type(original) == "table" then
      local row = {}
      for key, value in pairs(original) do row[key] = value end
      out[index] = row
    else
      out[index] = original
    end
  end
  return out
end

function World.nextObjectIndex(source)
  local objects = source and source.objects or source or {}
  local index = 1
  for _, object in ipairs(objects) do
    index = math.max(index, (tonumber(object.index) or 0) + 1)
  end
  return index
end

function World.appendObject(objects, definition)
  local row = {}
  for key, value in pairs(definition) do row[key] = value end
  row.index = row.index or World.nextObjectIndex(objects)
  objects[#objects + 1] = row
  return row
end

function World.casinoFloorBlocks()
  local blocks = { 63, 64, 64, 64, 64, 64, 64, 64, 64, 63 }
  for _ = 2, 8 do
    for _ = 1, 10 do blocks[#blocks + 1] = 32 end
  end
  for _, block in ipairs({ 27, 27, 27, 27, 61, 27, 27, 27, 27, 27 }) do
    blocks[#blocks + 1] = block
  end
  return blocks
end

function World.arenaFloorBlocks(topDoor, bottomDoor)
  local blocks = {}
  for row = 1, 9 do
    for col = 1, 10 do
      local block = 32
      if row == 1 or row == 9 then block = 27 end
      if topDoor and row == 1 and col == 5 then block = 61 end
      if bottomDoor and row == 9 and col == 5 then block = 61 end
      blocks[#blocks + 1] = block
    end
  end
  return blocks
end

function World.setObjectVisible(save, mapId, name, visible)
  save.objectToggles = save.objectToggles or {}
  save.objectToggles[mapId] = save.objectToggles[mapId] or {}
  save.objectToggles[mapId][name] = visible and true or false
end

return World
