return function(Helpers)
local World = {}

World.LOBBY = "ROCKET_ARENA_LOBBY"
World.ARENA = "ROCKET_BATTLE_ARENA"
World.STAIR_CELL = { x = 3, y = 10 }
World.OBJECTS = {
  terminal = {
    "ARENA_STATUS_TERMINAL_01", "ARENA_STATUS_TERMINAL_02",
    "ARENA_STATUS_TERMINAL_03", "ARENA_STATUS_TERMINAL_04",
  },
  security = "ARENA_DOORMAN",
  securityWing = "ARENA_DOORMAN_WING",
}

local function object(objects, name, sprite, text, x, y, range, movement, hidden)
  Helpers.appendObject(objects, {
    name = name, sprite = sprite, text = text, hidden = hidden,
    x = x, y = y, movement = movement or "STAY", range = range or "DOWN",
  })
end

function World.register(mod, loungeId)
  -- The two underground floors deliberately depend only on stock ROM
  -- tilesets. Minimal fixtures and total conversions without either tileset
  -- keep the arena unavailable instead of loading a half-rendered room.
  local lounge = mod.content.maps:get(loungeId)
  if not lounge or not mod.content.tilesets:get("LOBBY")
      or not mod.content.tilesets:get("GYM") then return false end
  World.mod = mod
  World.loungeId = loungeId

  -- The status terminal is the exact two-cabinet machine bank from Rocket
  -- Hideout's native FACILITY tiles. Its four cells cover the complete 2x2
  -- stair block so no fragment of the open route leaks through beforehand.
  for piece = 1, 4 do
    mod.content.sprites:register(("SPRITE_ARENA_TERMINAL_%02d"):format(piece), {
      image = ("save/mod-derived/blackjack_corner/world/rocket_equipment_%02d.png")
        :format(piece), frames = 1, trueColor = false,
    })
  end
  -- Block 67 is the complete native secret entrance used by Celadon's Game
  -- Corner. Clearance retracts the terminal covering it; no artificial
  -- staircase sprite or scripted teleport is involved.
  local loungeBlocks = Helpers.cloneList(lounge.blocks)
  local stairBlock = math.floor(World.STAIR_CELL.y / 2) * lounge.width
    + math.floor(World.STAIR_CELL.x / 2) + 1
  loungeBlocks[stairBlock] = 67
  local loungeWarps = Helpers.cloneList(lounge.warps)
  local stairWarp = #loungeWarps + 1
  loungeWarps[stairWarp] = {
    x = World.STAIR_CELL.x, y = World.STAIR_CELL.y,
    destMap = World.LOBBY, destWarp = 2,
  }
  local nextIndex = Helpers.nextObjectIndex(lounge)
  mod.content.maps:patch(loungeId, {
    blocks = loungeBlocks,
    warps = loungeWarps,
    objects = { __append = {
      { index = nextIndex, name = World.OBJECTS.terminal[1],
        sprite = "SPRITE_ARENA_TERMINAL_01", x = 2, y = 10,
        movement = "STAY", range = "DOWN" },
      { index = nextIndex + 1, name = World.OBJECTS.terminal[2],
        sprite = "SPRITE_ARENA_TERMINAL_02", x = 3, y = 10,
        movement = "STAY", range = "DOWN" },
      { index = nextIndex + 2, name = World.OBJECTS.terminal[3],
        sprite = "SPRITE_ARENA_TERMINAL_03", text = "TEXT_ARENA_TERMINAL",
        x = 2, y = 11, movement = "STAY", range = "DOWN" },
      { index = nextIndex + 3, name = World.OBJECTS.terminal[4],
        sprite = "SPRITE_ARENA_TERMINAL_04", text = "TEXT_ARENA_TERMINAL",
        x = 3, y = 11, movement = "STAY", range = "DOWN" },
    } },
  })

  local lobby = {}
  object(lobby, World.OBJECTS.security, "SPRITE_ROCKET", "TEXT_ARENA_GREETER",
    7, 2, "DOWN")
  object(lobby, World.OBJECTS.securityWing, "SPRITE_ROCKET",
    "TEXT_ARENA_DOORMAN", 12, 2, "DOWN")
  object(lobby, "ARENA_CASHIER", "SPRITE_CLERK", "TEXT_ARENA_CASHIER",
    4, 4, "DOWN")
  object(lobby, "ARENA_HOSTESS", "SPRITE_BEAUTY", "TEXT_ARENA_HOSTESS",
    15, 4, "DOWN")
  object(lobby, "ARENA_NERVOUS", "SPRITE_GENTLEMAN", "TEXT_ARENA_NERVOUS",
    4, 9, "LEFT_RIGHT", "WALK")
  object(lobby, "ARENA_VETERAN", "SPRITE_GAMBLER", "TEXT_ARENA_VETERAN",
    15, 9, "UP_DOWN", "WALK")
  object(lobby, "ARENA_SOCIALITE", "SPRITE_GIRL", "TEXT_ARENA_SOCIALITE",
    4, 14, "LEFT_RIGHT", "WALK")
  object(lobby, "ARENA_BROKE_VIP", "SPRITE_FISHER", "TEXT_ARENA_BROKE_VIP",
    15, 14, "LEFT_RIGHT", "WALK")
  mod.content.maps:register(World.LOBBY, {
    id = World.LOBBY, label = "RocketCasinoB1F", index = 1102,
    tileset = "LOBBY", width = 10, height = 9,
    blocks = Helpers.vipCasinoBlocks(),
    borderBlock = 15, palette = "SLOTS2",
    connections = {}, objects = lobby,
    signs = {
      { x = 2, y = 15, text = "TEXT_ARENA_LOBBY_PAINTING" },
      { x = 6, y = 15, text = "TEXT_ARENA_LOBBY_TROPHY" },
      { x = 13, y = 15, text = "TEXT_ARENA_LOBBY_TROPHY" },
      { x = 17, y = 15, text = "TEXT_ARENA_LOBBY_PAINTING" },
      { x = 3, y = 12, text = "TEXT_ARENA_LOBBY_TABLE" },
      { x = 17, y = 12, text = "TEXT_ARENA_LOBBY_TABLE" },
    },
    warps = {
      { x = 9, y = 1, destMap = World.ARENA, destWarp = 1 },
      { x = 9, y = 17, destMap = loungeId, destWarp = stairWarp },
      { x = 10, y = 17, destMap = loungeId, destWarp = stairWarp },
    },
  })
  -- Each event is a real Celadon machine cell. The player occupies the native
  -- chair immediately beside it and the engine opens its ordinary slot UI.
  mod.content.field:patch("slotMachines", {
    [World.LOBBY] = {
      { state = "ok", x = 7, y = 10 },
      { state = "ok", x = 7, y = 12 },
      { state = "ok", x = 7, y = 14 },
      { state = "ok", x = 12, y = 10 },
      { state = "ok", x = 12, y = 12 },
      { state = "ok", x = 12, y = 14 },
    },
  })

  local arena = {}
  object(arena, "ARENA_BOOKIE", "SPRITE_ROCKET", "TEXT_ARENA_BOOKIE",
    9, 3, "DOWN")
  for index, fan in ipairs({
    { "SPRITE_GAMBLER", "TEXT_ARENA_FAN_1", 3, 6, "RIGHT" },
    { "SPRITE_GIRL", "TEXT_ARENA_FAN_2", 16, 6, "LEFT" },
    { "SPRITE_FISHER", "TEXT_ARENA_FAN_3", 3, 10, "LEFT_RIGHT", "WALK" },
    { "SPRITE_MIDDLE_AGED_MAN", "TEXT_ARENA_FAN_4", 16, 10, "UP_DOWN", "WALK" },
    { "SPRITE_GENTLEMAN", "TEXT_ARENA_FAN_5", 2, 13, "RIGHT" },
    { "SPRITE_BEAUTY", "TEXT_ARENA_FAN_6", 17, 13, "LEFT" },
    { "SPRITE_ROCKET", "TEXT_ARENA_FAN_7", 7, 13, "RIGHT" },
    { "SPRITE_GRANNY", "TEXT_ARENA_FAN_8", 12, 13, "LEFT" },
  }) do
    object(arena, "ARENA_FAN_" .. index, fan[1], fan[2], fan[3], fan[4],
      fan[5], fan[6])
  end
  mod.content.maps:register(World.ARENA, {
    id = World.ARENA, label = "RocketCasinoB2F", index = 1103,
    tileset = "GYM", width = 10, height = 9,
    blocks = Helpers.rocketArenaBlocks(), borderBlock = 3, palette = "SLOTS1",
    connections = {}, signs = {
      { x = 9, y = 8, text = "TEXT_ARENA_BOOKIE" },
    }, objects = arena,
    warps = {
      { x = 9, y = 17, destMap = World.LOBBY, destWarp = 1 },
      { x = 10, y = 17, destMap = World.LOBBY, destWarp = 1 },
    },
  })
  return true
end

function World.sync(game, security, reload)
  local state = security and security.snapshot()
  if not state or not game or not game.save then return false end
  for _, name in ipairs(World.OBJECTS.terminal) do
    Helpers.setObjectVisible(game.save, World.loungeId or "BLACKJACK_LOUNGE",
      name, not state.stairsRevealed)
  end
  Helpers.setObjectVisible(game.save, World.LOBBY, World.OBJECTS.security,
    true)
  Helpers.setObjectVisible(game.save, World.LOBBY, World.OBJECTS.securityWing,
    true)
  if reload and World.mod and World.mod.world then
    local current = World.mod.world:current()
    if current and (current.mapId == (World.loungeId or "BLACKJACK_LOUNGE")
        or current.mapId == World.LOBBY) then
      World.mod.world:invalidateMap(current.mapId)
    end
  end
  return true
end

return World
end
