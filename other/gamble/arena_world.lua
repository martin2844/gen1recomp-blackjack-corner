local World = {}

World.LOBBY = "ROCKET_ARENA_LOBBY"
World.ARENA = "ROCKET_BATTLE_ARENA"

local function floorBlocks(topDoor, bottomDoor)
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

local function object(objects, name, sprite, text, x, y, range, movement)
  objects[#objects + 1] = {
    index = #objects + 1, name = name, sprite = sprite, text = text,
    x = x, y = y, movement = movement or "STAY", range = range or "DOWN",
  }
end

function World.register(mod, loungeId)
  -- Minimal compatibility fixtures and total conversions may not expose the
  -- Celadon Lounge/LOBBY tileset. In that case the arena chapter stays
  -- unavailable rather than registering maps with dangling references.
  if not mod.content.maps:get(loungeId)
      or not mod.content.tilesets:get("LOBBY") then return false end
  for piece = 1, 2 do
    mod.content.sprites:register(("SPRITE_ARENA_LIFT_%02d"):format(piece), {
      image = ("save/mod-derived/blackjack_corner/world/arena_lift_%02d.png")
        :format(piece), frames = 1, trueColor = true,
    })
  end
  for piece = 1, 8 do
    mod.content.sprites:register(("SPRITE_ARENA_RING_%02d"):format(piece), {
      image = ("save/mod-derived/blackjack_corner/world/arena_ring_%02d.png")
        :format(piece), frames = 1, trueColor = true,
    })
  end

  local lounge = mod.content.maps:get(loungeId)
  local nextIndex = 1
  for _, existing in ipairs(lounge.objects or {}) do
    nextIndex = math.max(nextIndex, (tonumber(existing.index) or 0) + 1)
  end
  mod.content.maps:patch(loungeId, { objects = { __append = {
    { index = nextIndex, name = "ARENA_LIFT_TOP", sprite = "SPRITE_ARENA_LIFT_01",
      x = 1, y = 10, movement = "STAY", range = "DOWN" },
    { index = nextIndex + 1, name = "ARENA_LIFT_PANEL", sprite = "SPRITE_ARENA_LIFT_02",
      text = "TEXT_ARENA_LIFT", x = 1, y = 11,
      movement = "STAY", range = "DOWN" },
  } } })

  local lobby = {}
  object(lobby, "ARENA_DOORMAN", "SPRITE_ROCKET", "TEXT_ARENA_DOORMAN",
    9, 4, "DOWN")
  object(lobby, "ARENA_CASHIER", "SPRITE_CLERK", "TEXT_ARENA_CASHIER",
    14, 7, "LEFT")
  object(lobby, "ARENA_EXIT", "SPRITE_ROCKET", "TEXT_ARENA_EXIT",
    9, 15, "UP")
  object(lobby, "ARENA_NERVOUS", "SPRITE_GENTLEMAN", "TEXT_ARENA_NERVOUS",
    4, 9, "LEFT_RIGHT", "WALK")
  object(lobby, "ARENA_VETERAN", "SPRITE_GAMBLER", "TEXT_ARENA_VETERAN",
    15, 13, "UP_DOWN", "WALK")
  mod.content.maps:register(World.LOBBY, {
    id = World.LOBBY, label = "RocketArenaLobby", index = 1102,
    tileset = "LOBBY", width = 10, height = 9,
    blocks = floorBlocks(true, true), borderBlock = 15, palette = "SLOTS2",
    connections = {}, signs = {}, warps = {}, objects = lobby,
  })

  local arena = {}
  for piece = 1, 8 do
    local column, row = (piece - 1) % 4, math.floor((piece - 1) / 4)
    object(arena, ("ARENA_RING_%02d"):format(piece),
      ("SPRITE_ARENA_RING_%02d"):format(piece),
      row == 1 and "TEXT_ARENA_BOOKIE" or nil, 7 + column, 7 + row, "DOWN")
  end
  object(arena, "ARENA_BOOKIE", "SPRITE_ROCKET", "TEXT_ARENA_BOOKIE",
    9, 10, "UP")
  object(arena, "ARENA_EXIT_GUARD", "SPRITE_ROCKET", "TEXT_ARENA_TO_LOBBY",
    9, 15, "UP")
  object(arena, "ARENA_FAN_1", "SPRITE_GAMBLER", "TEXT_ARENA_FAN_1",
    3, 9, "RIGHT")
  object(arena, "ARENA_FAN_2", "SPRITE_GIRL", "TEXT_ARENA_FAN_2",
    15, 9, "LEFT")
  object(arena, "ARENA_FAN_3", "SPRITE_FISHER", "TEXT_ARENA_FAN_3",
    4, 13, "LEFT_RIGHT", "WALK")
  object(arena, "ARENA_FAN_4", "SPRITE_MIDDLE_AGED_MAN", "TEXT_ARENA_FAN_4",
    14, 13, "UP_DOWN", "WALK")
  mod.content.maps:register(World.ARENA, {
    id = World.ARENA, label = "RocketBattleArena", index = 1103,
    tileset = "LOBBY", width = 10, height = 9,
    blocks = floorBlocks(false, true), borderBlock = 15, palette = "SLOTS1",
    connections = {}, signs = {}, warps = {}, objects = arena,
  })
  return true
end

return World
