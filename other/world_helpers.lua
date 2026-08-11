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

local function flattenRows(rows)
  local blocks = {}
  for _, row in ipairs(rows) do
    for _, block in ipairs(row) do blocks[#blocks + 1] = block end
  end
  return blocks
end

-- B1 is a deliberate remix of the stock GAME CORNER, DINER and CELADON MART
-- vocabulary. The room keeps a strong central promenade: reception and the
-- arena terminal sit on its axis, while real cabinet banks and smaller social
-- pockets occupy the wings.
function World.vipCasinoBlocks()
  return flattenRows({
    { 15, 15, 15, 15, 12, 13, 15, 15, 15, 15 },
    { 10, 10, 10, 51, 32, 32, 51, 10, 10, 10 },
    { 47, 47, 47, 51, 32, 32, 51, 47, 47, 47 },
    { 29, 32, 33, 29, 32, 32, 29, 32, 33, 29 },
    { 58, 32, 32, 58, 32, 32, 58, 32, 32, 58 },
    { 57, 31, 33, 57, 32, 32, 57, 31, 33, 57 },
    { 57, 31, 33, 57, 32, 32, 57, 31, 33, 57 },
    { 56, 31, 33, 56, 32, 32, 56, 31, 33, 56 },
    { 27, 27, 27, 27, 40, 41, 27, 27, 27, 27 },
  })
end

-- B2 is TEAM ROCKET's illicit fifth Elite Four chamber. Every block belongs
-- to the stock GYM tileset used by Lorelei and Bruno: a ceremonial center
-- aisle, a raised fighting floor, rock-lined spectator pockets and the real
-- south-room warp geometry used by those encounters.
function World.rocketArenaBlocks()
  return flattenRows({
    { 33, 33, 33, 33, 36, 36, 33, 33, 33, 33 },
    { 2, 24, 24, 24, 24, 24, 24, 24, 24, 2 },
    { 2, 24, 5, 5, 5, 5, 5, 5, 24, 2 },
    { 2, 24, 50, 5, 5, 5, 5, 49, 24, 2 },
    { 2, 24, 5, 5, 5, 5, 5, 5, 24, 2 },
    { 2, 24, 50, 5, 5, 5, 5, 49, 24, 2 },
    { 2, 24, 24, 5, 5, 5, 5, 24, 24, 2 },
    { 2, 32, 32, 32, 5, 5, 32, 32, 32, 2 },
    { 2, 2, 2, 68, 5, 5, 68, 2, 2, 2 },
  })
end

function World.setObjectVisible(save, mapId, name, visible)
  save.objectToggles = save.objectToggles or {}
  save.objectToggles[mapId] = save.objectToggles[mapId] or {}
  save.objectToggles[mapId][name] = visible and true or false
end

return World
